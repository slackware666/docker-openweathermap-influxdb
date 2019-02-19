#!/usr/bin/env ruby

require 'uri'
require 'net/http'
require 'json'
require 'pp'
require 'influxdb'

INFLUXB_NAME = ENV['INFLUXDB_NAME'] || 'openweathermap'
INFLUXB_HOST = ENV['INFLUXDB_HOST'] || 'localhost'
INFLUXB_USER = ENV['INFLUXDB_USER'] || ''
INFLUXB_PASS = ENV['INFLUXDB_PASS'] || ''

OPENWEATHERMAP_API_KEY = ENV['OPENWEATHERMAP_API_KEY']
OPENWEATHERMAP_CITIES  = ENV['OPENWEATHERMAP_CITIES'].split(',') || ['Buxtehude']

SLEEP = ENV['INTERVAL'] || 300

# Create InfluxDB client
unless INFLUXB_USER == '' && INFLUXB_PASS == ''
    influxdb = InfluxDB::Client.new INFLUXB_NAME, host: INFLUXB_HOST, username: INFLUXB_USER, password: INFLUXB_PASS
else
    influxdb = InfluxDB::Client.new INFLUXB_NAME, host: INFLUXB_HOST
end

# Create database if needed
unless influxdb.list_databases.map{|db| db['name']}.include?(INFLUXB_NAME)
    influxdb.create_database(INFLUXB_NAME)
end

loop do

    # Get weather for cities
    OPENWEATHERMAP_CITIES.each do |city|
        uri          = URI("https://api.openweathermap.org/data/2.5/weather?q=#{city}&appid=#{OPENWEATHERMAP_API_KEY}&units=metric")
        result       = Net::HTTP.get(uri)
        weather_data = JSON.parse(result)

        # write weather data
        data = {
            values: {
                longitude: weather_data['coord']['lon'],
                latitude: weather_data['coord']['lat'],
                temperature: weather_data['main']['temp'].to_f,
                pressure: weather_data['main']['pressure'].to_f,
                humdity: weather_data['main']['humidity'].to_f,
                temperature_min: weather_data['main']['temp_min'].to_f,
                temperature_max: weather_data['main']['temp_max'].to_f,
                wind_speed: weather_data['wind']['speed'].to_f || 0.0,
                wind_direction: weather_data['wind']['deg'].to_i || 0,
                snow_1h: weather_data.has_key?('snow') && weather_data['snow'].has_key?('1h') ? weather_data['snow']['1h'] : 0.0,
                snow_3h: weather_data.has_key?('snow') && weather_data['snow'].has_key?('3h') ? weather_data['snow']['3h'] : 0.0,
                rain_1h: weather_data.has_key?('rain') && weather_data['rain'].has_key?('1h') ? weather_data['rain']['1h'] : 0.0,
                rain_3h: weather_data.has_key?('rain') && weather_data['rain'].has_key?('3h') ? weather_data['rain']['3h'] : 0.0,
                clouds: weather_data['clouds']['all'],
                datetime: weather_data['dt'],
                sunrise: weather_data['sys']['sunrise'],
                sunset: weather_data['sys']['sunset'],
                id: weather_data['id']
            }
        }
        
        pp data

        influxdb.write_point(city, data)
    end

    sleep SLEEP

end