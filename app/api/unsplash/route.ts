import { NextRequest, NextResponse } from 'next/server';

interface UnsplashPhoto {
  id: string;
  urls: {
    raw: string;
    full: string;
    regular: string;
    small: string;
    thumb: string;
  };
  user: {
    name: string;
    links: {
      html: string;
    };
  };
  links: {
    download_location: string;
  };
  tags?: Array<{
    title: string;
  }>;
}

interface UnsplashSearchResponse {
  results: UnsplashPhoto[];
  total: number;
  total_pages: number;
}

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const action = searchParams.get('action'); // 'random' or 'search'
    const query = searchParams.get('query');
    const page = searchParams.get('page') || '1';
    const perPage = searchParams.get('per_page') || '10';

    if (!process.env.UNSPLASH_ACCESS_KEY) {
      console.error('UNSPLASH_ACCESS_KEY not configured');
      return NextResponse.json(
        { error: 'Unsplash API key not configured' },
        { status: 500 }
      );
    }

    const accessKey = process.env.UNSPLASH_ACCESS_KEY;
    const baseURL = 'https://api.unsplash.com';

    let apiUrl: string;
    let url: URL;

    if (action === 'random') {
      apiUrl = `${baseURL}/photos/random`;
      url = new URL(apiUrl);
      if (query) {
        url.searchParams.set('query', query);
      }
    } else if (action === 'search' && query) {
      apiUrl = `${baseURL}/search/photos`;
      url = new URL(apiUrl);
      url.searchParams.set('query', query);
      url.searchParams.set('page', page);
      url.searchParams.set('per_page', perPage);
    } else {
      return NextResponse.json(
        { error: 'Invalid action or missing query parameter' },
        { status: 400 }
      );
    }

    url.searchParams.set('client_id', accessKey);

    console.log(`Fetching from Unsplash: ${url.toString()}`);

    const response = await fetch(url.toString(), {
      headers: {
        'Accept-Version': 'v1',
        'Authorization': `Client-ID ${accessKey}`
      }
    });

    if (!response.ok) {
      console.error(`Unsplash API error: ${response.status} ${response.statusText}`);
      return NextResponse.json(
        { error: `Unsplash API error: ${response.status}` },
        { status: response.status }
      );
    }

    const data = await response.json();

    // If it's a search request, return the results array
    if (action === 'search') {
      const searchData = data as UnsplashSearchResponse;
      return NextResponse.json(searchData.results);
    }

    // If it's a random photo request, return the single photo
    const photoData = data as UnsplashPhoto;
    return NextResponse.json([photoData]);

  } catch (error) {
    console.error('Error in Unsplash API route:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const { action, photoId } = await request.json();

    if (action !== 'track_download' || !photoId) {
      return NextResponse.json(
        { error: 'Invalid request. Requires action=track_download and photoId' },
        { status: 400 }
      );
    }

    if (!process.env.UNSPLASH_ACCESS_KEY) {
      return NextResponse.json(
        { error: 'Unsplash API key not configured' },
        { status: 500 }
      );
    }

    const accessKey = process.env.UNSPLASH_ACCESS_KEY;
    const trackUrl = `https://api.unsplash.com/photos/${photoId}/download?client_id=${accessKey}`;

    // Track the download (fire and forget)
    fetch(trackUrl).catch(err => {
      console.warn('Failed to track download:', err);
    });

    return NextResponse.json({ success: true });

  } catch (error) {
    console.error('Error in Unsplash track download:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}


