require 'bundler'
Bundler.require

Dotenv.load

Trello.configure do |config|
  config.developer_public_key = ENV['TRELLO_DEVELOPER_PUBLIC_KEY']
  config.member_token = ENV['TRELLO_MEMBER_TOKEN']
end

BOARD_ID = ARGV[0]
USERNAME = ARGV[1]

raise 'No board id' if BOARD_ID.nil?

board = Trello::Board.find(BOARD_ID)
cards = board.cards.reject { |b| b.due.nil? || b.due < Time.now }
cards.reject! { |b| b.members.none? { |m| m.username == USERNAME } } unless USERNAME.nil?
groups = cards.group_by(&:due).sort.to_h

tasks = ''

groups.each do |due, cards|
  tasks << "# #{due.strftime('%Y/%-m/%-d')}\n"
  cards.each do |card|
    members = card.members.map(&:username)
    tasks << "- [ ] #{card.url} #{card.name} #{members.join(', ') if USERNAME.nil?}\n"
  end
  tasks << "\n"
end

puts tasks

ChatWork.api_key = ENV['CHATWORK_API_KEY']
ChatWork::Message.create(room_id: ENV['CHATWORK_ROOM_ID'], body: tasks) if ChatWork.api_key
