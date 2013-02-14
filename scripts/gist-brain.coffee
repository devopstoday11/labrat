# Description:
#   Stores the brain of the robot in a gist.
#
# Configuration:
#   HUBOT_GIST_BRAIN_OAUTH_TOKEN
#   HUBOT_GIST_BRAIN_GIST
#   HUBOT_GIST_BRAIN_FILENAME

gistBrainToken = "#{process.env.HUBOT_GIST_BRAIN_OAUTH_TOKEN}"
gistBrainGist = "#{process.env.HUBOT_GIST_BRAIN_GIST}"
gistBrainFilename = "#{process.env.HUBOT_GIST_BRAIN_FILENAME}"

previousBrain = ""

read_gist_brain = (robot) ->
	robot.http("https://api.github.com/gists/#{gistBrainGist}")
		.headers(Authorization: "token #{gistBrainToken}", Accept: "application/json")
		.get() (err, res, body) ->
			if err
				robot.logger.error "#{err}"
				return
			contents = JSON.parse(body)
			brainContents = contents.files[gistBrainFilename].content
			if brainContents
				console.log brainContents
				previousBrain = brainContents
				robot.logger.info "Reading Gist Brain"
				robot.brain.mergeData JSON.parse(brainContents)

write_gist_brain = (robot, brainData) ->
	json = {}
	json[gistBrainFilename] = {content: brainData}
	gistContent = JSON.stringify({files: json})
	robot.http("https://api.github.com/gists/#{gistBrainGist}")
		.headers(Authorization: "token #{gistBrainToken}", Accept: "application/json", "Content-Type": "application/json")
		.patch(gistContent) (err, res, body) ->
			if err
				robot.logger.error "#{err}"
				return
			contents = JSON.parse(body)
			robot.logger.info "Dumped brain to Gist"


module.exports = (robot) ->
	read_gist_brain robot

	robot.brain.on 'save', (data = {}) ->
		newBrain = JSON.stringify(data)
		if previousBrain != newBrain 
			previousBrain = newBrain
			console.log newBrain
			write_gist_brain robot, newBrain

	robot.brain.on 'close', ->
		robot.logger.info "Bye bye..."