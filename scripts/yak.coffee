# Description:
#   Shave a yak
#
# Configuration:
#   None
#
# Commands:
#   shave (a) yak - Try to shave a yak.

module.exports = (robot) ->

	robot.respond /shave\s*[a]\s*yak$/i, (msg) ->
		msg.send "A hairy yak is a happy yak..."