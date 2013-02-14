# Description:
#   Queries Zendesk for information about support tickets
#
# Configuration:
#   HUBOT_ZENDESK_USER
#   HUBOT_ZENDESK_PASSWORD
#   HUBOT_ZENDESK_SUBDOMAIN
#
# Commands:
#   (all) tickets - returns the total count of all unsolved tickets. The 'all'
#                   keyword is optional.
#   new tickets - returns the count of all new tickets
#   open tickets - returns the count of all open tickets
#   list (all) tickets - returns a list of all unsolved tickets. The 'all'
#                   keyword is optional.
#   list new tickets - returns a list of all new tickets
#   list open tickets - returns a list of all open tickets
#   ticket <ID> - returns informationa about the specified ticket

sys = require 'sys' # Used for debugging

zendesk_user = "#{process.env.HUBOT_ZENDESK_USER}"
zendesk_password = "#{process.env.HUBOT_ZENDESK_PASSWORD}"
auth = new Buffer("#{zendesk_user}:#{zendesk_password}").toString('base64')
zendesk_url = "https://#{process.env.HUBOT_ZENDESK_SUBDOMAIN}.zendesk.com/api/v2"

potatoheads = ["jeroen", "vincent", "paul", "andrew", "martin", "ravan", "hes", "ric", "jasper", "mike"]
potatohead = Math.floor(Math.random() * potatoheads.length)

console.log potatoheads[potatohead] + " is next"

queries =
  unsolved: "search.json?query=\"status<solved type:ticket\""
  open: "search.json?query=\"status:open type:ticket\""
  new: "search.json?query=\"status:new type:ticket\""
  tickets: "tickets"
  users: "users"

next_potato = -> potatoheads[potatohead++]

potato_update = (the_potato) -> ticket:{custom_fields:[{id: 22270006, value: "#{the_potato}"}],fields:[{id: 22270006, value: "#{the_potato}"}]}

zendesk_put = (msg, url, data, handler) ->
  msg.http("#{zendesk_url}/#{url}")
    .headers(Authorization: "Basic #{auth}", Accept: "application/json", "Content-Type": "application/json")
    .put(JSON.stringify(data)) (err, res, body) ->
      if err
        msg.send "zendesk says: #{err}"
        return
      content = JSON.parse(body)
      handler content

zendesk_request = (msg, url, handler) ->
  msg.http("#{zendesk_url}/#{url}")
    .headers(Authorization: "Basic #{auth}", Accept: "application/json")
    .get() (err, res, body) ->
      if err
        msg.send "zendesk says: #{err}"
        return
      content = JSON.parse(body)
      handler content

# FIXME this works about as well as a brick floats
zendesk_user = (msg, user_id) ->
  zendesk_request msg, "#{queries.users}/#{user_id}.json", (result) ->
    if result.error
      msg.send result.description
      return
    result.user

find_potato = (result) ->
  for customField in result.custom_fields
    if customField.id == 22270006
      return customField.value

module.exports = (robot) ->

  robot.respond /(all )?tickets$/i, (msg) ->
    zendesk_request msg, queries.unsolved, (results) ->
      ticket_count = results.count
      msg.send "#{ticket_count} unsolved tickets"

  robot.respond /new tickets$/i, (msg) ->
    zendesk_request msg, queries.new, (results) ->
      ticket_count = results.count
      msg.send "#{ticket_count} new tickets"

  robot.respond /open tickets$/i, (msg) ->
    zendesk_request msg, queries.open, (results) ->
      ticket_count = results.count
      msg.send "#{ticket_count} open tickets"

  robot.respond /list (all )?tickets$/i, (msg) ->
    zendesk_request msg, queries.unsolved, (results) ->
      message = ""
      for result in results.results
        potato = find_potato result
        message += "*#{result.id}* is #{result.status} (assigned to *#{potato}*): #{result.subject}\n"
      msg.send message

  robot.respond /list new tickets$/i, (msg) ->
    zendesk_request msg, queries.new, (results) ->
      for result in results.results
        msg.send "#{result.id} is #{result.status}: #{result.subject}"

  robot.respond /list open tickets$/i, (msg) ->
    zendesk_request msg, queries.open, (results) ->
      for result in results.results
        msg.send "#{result.id} is #{result.status}: #{result.subject}"

  robot.respond /ticket ([\d]+)$/i, (msg) ->
    ticket_id = msg.match[1]
    zendesk_request msg, "#{queries.tickets}/#{ticket_id}.json", (result) ->
      if result.error
        msg.send result.description
        return
      message = "#{result.ticket.subject} ##{result.ticket.id} (#{result.ticket.status.toUpperCase()})"
      message += "\nUpdated: #{result.ticket.updated_at}"
      message += "\nAdded: #{result.ticket.created_at}"
      message += "\nDescription:\n-------\n#{result.ticket.description}\n--------"
      msg.send message

  robot.respond /assign ticket ([\d]+) to ([a-z]+)$/, (msg) ->
    ticket_id = msg.match[1]
    the_potato = msg.match[2]
    message = potato_update the_potato
    zendesk_put msg, "#{queries.tickets}/#{ticket_id}.json", message, (result) ->
      msg.send "*#{result.ticket.id}* successfully assigned to *#{the_potato}*"

  robot.respond /potato ticket ([\d]+)$/, (msg) ->
    ticket_id = msg.match[1]
    the_potato = next_potato()
    message = potato_update the_potato
    console.log "Next potato = #{potatoheads[potatohead]}"
    zendesk_put msg, "#{queries.tickets}/#{ticket_id}.json", message, (result) ->
      msg.send "*#{result.ticket.id}* successfully assigned to *#{the_potato}*"
