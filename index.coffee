fs = require 'fs'
Lame = require 'lame'
through = require 'through'
Speaker = require 'speaker'

timeKeeper = ->
	# Maximum accepted deviation from ideal timing
	EPSILON_MS = 20
	EPSILON_BYTES = EPSILON_MS * 44.1 * 2 * 2

	# State variables
	actualBytes = 0
	start = null

	# The actual stream processing function
	return through (chunk) ->
		# Initialise start the at the first chunk of data
		if start is null then start = Date.now()

		# Derive the bytes that should have been processed if there was no time skew
		idealBytes = (Date.now() - start) * 44.1 * 2 * 2

		diffBytes = actualBytes - idealBytes
		actualBytes += chunk.length
		console.log('Time deviation:', (diffBytes / 44.1 / 2 / 2).toFixed(2) + 'ms')

		# The buffer size should be a multiple of 4
		diffBytes = diffBytes - (diffBytes % 4)

		# Only correct the stream if we're out of the EPSILON region
		if -EPSILON_BYTES < diffBytes < EPSILON_BYTES
			correctedChunk = chunk
		else
			console.log('Epsilon exceeded! correcting')
			correctedChunk = new Buffer(chunk.length + diffBytes)
			chunk.copy(correctedChunk)

		@emit('data', correctedChunk)


# Play a demo song
fs.createReadStream(__dirname + '/utopia.mp3')
	.pipe(new Lame.Decoder())
	.pipe(timeKeeper())
	.pipe(new Speaker())
