#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'
require 'optparse'

options = {
  api_key: ENV["OPENAI_API_KEY"],  # default to environment variable if set
  model: 'gpt-3.5-turbo',          # default model
  max_tokens: 150                  # default max tokens
}

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options] <message>"

  opts.on("-k", "--api-key KEY", "OpenAI API Key") do |key|
    options[:api_key] = key
  end

  opts.on("-m", "--model MODEL", "Model name (default: gpt-3.5-turbo)") do |model|
    options[:model] = model
  end

  opts.on("-t", "--max-tokens TOKENS", Integer, "Maximum number of tokens (default: 150)") do |tokens|
    options[:max_tokens] = tokens
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

message = ARGV[0]
if message.nil? || message.empty?
  puts "Please provide a message. Use -h for help."
  exit(1)
end

def send_chat_to_openai(message, api_key, model, max_tokens)
  uri = URI.parse("https://api.openai.com/v1/chat/completions")

  request = Net::HTTP::Post.new(uri)
  request.content_type = "application/json"
  request["Authorization"] = "Bearer #{api_key}"
  request.body = JSON.dump({
    "model" => model,
    "messages" => [
      {"role" => "system", "content" => "You are a helpful assistant."},
      {"role" => "user", "content" => message}
    ],
    "max_tokens" => max_tokens.to_i
  })

  req_options = {
    use_ssl: uri.scheme == "https",
  }

  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end

  JSON.parse(response.body)
end

response = send_chat_to_openai(message, options[:api_key], options[:model], options[:max_tokens])

if response.has_key? "error"
  puts response["error"]
else
  puts response["choices"][0]["message"]["content"].strip
end
