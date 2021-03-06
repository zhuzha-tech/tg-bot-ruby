require "telegram/bot"
require "aws-sdk-ec2"
require "json"

TOKEN = ENV['TELEGRAM_TOKEN']
AWS_REGION = 'eu-central-1'
INSTANCE_ID = 'i-06f46d854347c6a22'

class MyBot
  def initialize
    file = File.read("lib/choose.json")
    choose = JSON.parse(file)
    logger = Logger.new(STDOUT, Logger::DEBUG, datetime_format: '%Y-%m-%d %H:%M:%S')
    ec2_resource = Aws::EC2::Resource.new(region: AWS_REGION)

    Telegram::Bot::Client.run(TOKEN, logger: logger) do |bot|
      bot.listen do |message|
        case message
        when Telegram::Bot::Types::CallbackQuery
          title = choose[message.data]["title"]
          value = choose[message.data]["options"]
          res = value.map do |hash|
            Telegram::Bot::Types::InlineKeyboardButton.new(text: hash["text"], url: hash["url"])
          end
          markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: res)

          bot.api.edit_message_text(chat_id: message.from.id, message_id: message.message.message_id, text: "Тема #{title}. Отличный выбор \u{1F44D}", reply_markup: markup)
        when Telegram::Bot::Types::Message
          case message.text
          when "/start"
            question = "Hi, #{message.from.first_name} \u{1F91D}\u{1F447}!!!"
            buttons = [
              Telegram::Bot::Types::InlineKeyboardButton.new(text: "MEDICINE", callback_data: "medicine"),
              Telegram::Bot::Types::InlineKeyboardButton.new(text: "RELATIONSHIP", callback_data: "relationship"),
              Telegram::Bot::Types::InlineKeyboardButton.new(text: "SPORT", callback_data: "sport"),
              Telegram::Bot::Types::InlineKeyboardButton.new(text: "WILLPOWER", callback_data: "willpower"),
              Telegram::Bot::Types::InlineKeyboardButton.new(text: "JUSTICE", callback_data: "justice"),
              Telegram::Bot::Types::InlineKeyboardButton.new(text: "PSYCHOLOGY, PHILOSOPHY", callback_data: "psychology"),
              Telegram::Bot::Types::InlineKeyboardButton.new(text: "WAR", callback_data: "war"),
              Telegram::Bot::Types::InlineKeyboardButton.new(text: "SCIENCE", callback_data: "science"),
              Telegram::Bot::Types::InlineKeyboardButton.new(text: "FOR SOUL (not based on real life)", callback_data: "for_the_soul"),
            ]
            keyboard = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons)
            bot.api.send_message(chat_id: message.chat.id, text: question, reply_markup: keyboard)
          when "/stop"
            kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
            bot.api.send_message(chat_id: message.chat.id, text: "Sad, that you leave \u{1F622} \u{1F618} \u{1F60A}", reply_markup: kb)
          when "/status"
            response = ec2_resource.instances
            if response.count.zero?
              logger.info "No instances found."
            else
              text = ""
              response.each do |instance|
                text += "\n#{instance.id} - #{instance.state.name} - #{instance.tags[0].value}"
                unless instance.public_ip_address.nil?
                  text += " - #{instance.public_ip_address}"
                end
                text += "\n"
              end
              bot.api.send_message chat_id: message.chat.id, text: text
            end
          when "/toggle"
            instance = ec2_resource.instance INSTANCE_ID
            logger.info "Instance #{instance.id} is #{instance.state.name}."
            case instance.state.name
            when "running"
              instance.stop
              instance.wait_until_stopped max_attempts: 10, delay: 5
            when "stopped"
              instance.start
              instance.wait_until_running max_attempts: 10, delay: 5
            end
            bot.api.send_message chat_id: message.from.id, text: "Instance #{instance.id} is #{instance.state_transition_reason}/#{instance.state_reason}"
          when "/write_me"
            kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
            bot.api.send_message chat_id: message.chat.id, text: "Okay \u{1F60A}", reply_markup: kb
          end
        end
      end
    end
  end
end
