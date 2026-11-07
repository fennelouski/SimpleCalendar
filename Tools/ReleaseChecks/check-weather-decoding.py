from pathlib import Path
import subprocess,tempfile,urllib.request,json
root=Path(__file__).resolve().parents[2]
fixture=Path(__file__).parent/'fixtures/open-meteo-response.json'
# Captured from Open-Meteo's public Berlin forecast API on 2026-09-28, CC BY 4.0.
# https://open-meteo.com/en/docs (query fields remain in WeatherManager.swift).
s=(root/'Simple Calendar/WeatherManager.swift').read_text().split('#if os(tvOS) || NO_WEATHERKIT\n// MARK:')[0]
s+='''
@main struct FixtureCheck {
 static func main() throws {
  let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
  let response = try decodeOpenMeteoResponse(from: data)
  precondition(response.current?.weathercode != nil)
  precondition(response.currentWeather == nil)
  let daily = response.daily!
  precondition(daily.time.count == 2)
  precondition(daily.weathercode?.count == 2)
  precondition(daily.time.allSatisfy { openMeteoDate($0) != nil })
  precondition(openMeteoDate("2026-09-28T12:15") != nil)
  print("PASS: real provider current weather_code and daily weather_code decode")
  print("PASS: forecast works without obsolete current_weather field")
  print("PASS: provider date-only and local-minute dates parse")
 }
}
'''
with tempfile.TemporaryDirectory() as tmp:
 path=Path(tmp)/'Check.swift';path.write_text(s);exe=Path(tmp)/'Check'
 subprocess.run(['xcrun','swiftc','-parse-as-library',str(path),'-o',str(exe)],check=True)
 subprocess.run([str(exe),str(fixture)],check=True)
