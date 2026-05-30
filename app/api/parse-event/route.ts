import { NextRequest, NextResponse } from 'next/server';
import OpenAI from 'openai';

interface ParsedEvent {
  title: string;
  startDate?: string;
  endDate?: string;
  isAllDay?: boolean;
  location?: string;
  notes?: string;
  color?: string; // Hex color code like "#FF6B6B"
  emoji?: string; // Single emoji character
  recurrence?: {
    frequency: 'daily' | 'weekly' | 'monthly' | 'yearly';
    interval: number;
    endDate?: string;
    daysOfWeek?: number[]; // 0 = Sunday, 1 = Monday, etc.
  };
  participants?: string[];
}

export async function POST(request: NextRequest) {
  try {
    if (!process.env.OPENAI_API_KEY) {
      return NextResponse.json(
        { error: 'OpenAI API key not configured' },
        { status: 500 }
      );
    }

    const openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY,
    });

    const { text, currentDate } = await request.json();

    if (!text || typeof text !== 'string') {
      return NextResponse.json(
        { error: 'Text is required and must be a string' },
        { status: 400 }
      );
    }

    const systemPrompt = `You are an AI assistant that parses natural language descriptions of calendar events and converts them into structured event data.

Given a natural language description of an event, extract and structure the following information:

1. **title**: The event title/summary
2. **startDate**: ISO 8601 date-time string (if not specified, use the current date if provided)
3. **endDate**: ISO 8601 date-time string (if not specified, infer from duration)
4. **isAllDay**: Boolean indicating if the event lasts all day
5. **location**: Location/address if mentioned
6. **notes**: Additional notes or description
7. **color**: Hex color code (like "#FF6B6B") based on user mention or event type. Use colors like:
   - Blue (#4A90E2) for work/meetings
   - Green (#7ED321) for personal/health
   - Purple (#9B59B6) for family/social
   - Orange (#F5A623) for creative/hobbies
   - Red (#D0021B) for urgent/important
   - Pink (#E91E63) for celebrations
   - Teal (#00BCD4) for learning/education
8. **emoji**: Single appropriate emoji character based on event type:
   - 📅 for general meetings
   - 👨‍⚕️ for doctor/health appointments
   - 🎓 for school/education
   - 🍽️ for meals/dining
   - 🎉 for celebrations/parties
   - 💼 for work/business
   - 🏃‍♂️ for exercise/sports
   - 🎨 for creative activities
   - 📖 for reading/learning
   - ✈️ for travel
9. **recurrence**: If the event repeats, include frequency, interval, and end date
10. **participants**: Names or email addresses of participants if mentioned

Key parsing rules:
- If no specific date is mentioned, use the currentDate as the base date
- If times are mentioned, combine with the current date or inferred date
- Handle relative time expressions like "tomorrow", "next week", "in 2 hours"
- Recognize recurring patterns like "every Monday", "daily", "weekly for 3 weeks"
- For school schedules, infer reasonable times if not specified (e.g., "school" might mean 8:00-15:00)
- For appointments, infer reasonable durations if not specified (e.g., "doctor appointment" might be 1 hour)
- Parse location information and try to identify specific addresses or place names
- Extract color preferences if mentioned (e.g., "blue meeting", "red event")
- Choose appropriate emoji based on event context and type
- Handle multiple events if the description contains more than one

Return the response as valid JSON matching the ParsedEvent interface. If the description doesn't seem to describe a calendar event, return an error.`;

    const response = await openai.chat.completions.create({
      model: 'gpt-5.1-mini', // Using GPT-5.1 mini for cost-effective parsing
      messages: [
        {
          role: 'system',
          content: systemPrompt
        },
        {
          role: 'user',
          content: `Parse this event description: "${text}"${currentDate ? `\n\nCurrent date context: ${currentDate}` : ''}`
        }
      ],
      max_tokens: 1000,
      temperature: 0.1, // Low temperature for consistent parsing
    });

    const content = response.choices[0]?.message?.content;
    if (!content) {
      return NextResponse.json(
        { error: 'No response from OpenAI' },
        { status: 500 }
      );
    }

    try {
      const parsedEvent: ParsedEvent = JSON.parse(content);

      // Validate the parsed event has required fields
      if (!parsedEvent.title) {
        return NextResponse.json(
          { error: 'Could not extract event title from description' },
          { status: 400 }
        );
      }

      return NextResponse.json(parsedEvent);
    } catch (parseError) {
      console.error('Failed to parse OpenAI response as JSON:', content);
      return NextResponse.json(
        { error: 'Failed to parse event data', rawResponse: content },
        { status: 500 }
      );
    }

  } catch (error) {
    console.error('Error in parse-event API:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
