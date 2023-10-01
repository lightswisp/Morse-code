require "wavefile"

OUTPUT_FILENAME = "mysound.wav"
SAMPLE_RATE = 44100
SECONDS_TO_GENERATE = 2
TWO_PI = 2 * Math::PI
RANDOM_GENERATOR = Random.new
AMPLITUDE	= 0.6 # Should be between 0.0 (silence) and 1.0 (full volume).
                # Amplitudes above 1.0 will result in clipping distortion.

DEFAULT_FREQUENCY = 880.0

MORSE_CODE_SPEED = 0.05

MORSE_CODE_RATIO = {
	:dot => 1,
	:dash => 3,
	:symbol_space => 1,
	:letter_space => 3,
	:word_space => 7
}

# A A
# 
# .- .-
# 
# :dot :symbol_space :dash :word_space :dot :symbol_space :dash
# 
# [
	# [0.1, DEFAULT_FREQUENCY, AMPLITUDE], # :dot
	# [0.1, DEFAULT_FREQUENCY, AMPLITUDE]  # :symbol space
# ]



MORSE_CODE = {
  'A' => '.-',     'B' => '-...',   'C' => '-.-.',   'D' => '-..',
  'E' => '.',      'F' => '..-.',   'G' => '--.',    'H' => '....',
  'I' => '..',     'J' => '.---',   'K' => '-.-',    'L' => '.-..',
  'M' => '--',     'N' => '-.',     'O' => '---',    'P' => '.--.',
  'Q' => '--.-',   'R' => '.-.',    'S' => '...',    'T' => '-',
  'U' => '..-',    'V' => '...-',   'W' => '.--',    'X' => '-..-',
  'Y' => '-.--',   'Z' => '--..',
  '0' => '-----',  '1' => '.----',  '2' => '..---',  '3' => '...--',
  '4' => '....-',  '5' => '.....',  '6' => '-....',  '7' => '--...',
  '8' => '---..',  '9' => '----.',
  ' ' => ' '       # Space
}

def generate_morse_code(text)
	result = []
	text = text.upcase.split("")
	text.each_with_index do |letter, l_index|
		if letter == " " 
			result << [MORSE_CODE_RATIO[:word_space] * MORSE_CODE_SPEED, DEFAULT_FREQUENCY, 0] # :word_space * MORSE_CODE_SPEED
		else
			morse_letter = MORSE_CODE[letter]
			morse_letter = morse_letter.split("")
			morse_letter.each_with_index { |morse_symbol, m_index|
				if morse_symbol == "."
					result << [MORSE_CODE_RATIO[:dot] * MORSE_CODE_SPEED, DEFAULT_FREQUENCY, AMPLITUDE] # :dot * MORSE_CODE_SPEED
					break if !morse_letter[m_index + 1]
				elsif morse_symbol == "-"
					result << [MORSE_CODE_RATIO[:dash] * MORSE_CODE_SPEED, DEFAULT_FREQUENCY, AMPLITUDE] # :dash * MORSE_CODE_SPEED
					break if !morse_letter[m_index + 1]
				end
				result << [MORSE_CODE_RATIO[:symbol_space] * MORSE_CODE_SPEED, DEFAULT_FREQUENCY, 0] # :symbol_space * MORSE_CODE_SPEED
			}
			break if !text[l_index + 1]
			result << [MORSE_CODE_RATIO[:letter_space] * MORSE_CODE_SPEED, DEFAULT_FREQUENCY, 0] if text[l_index + 1] != " "# :letter_space * MORSE_CODE_SPEED
		end
	end
	return result
end

def main

	
  # Generate sample data at the given frequency and amplitude.
  # The sample rate indicates how many samples we need to generate for
  # music_sample = [
  	# [1, 440.0, AMPLITUDE],
  	# [1, 490.0, AMPLITUDE],
  	# [1, 530.0, AMPLITUDE]
  # ]
  # samples = generate_sequence_of_sample_data(music_sample)
  #num_samples = SAMPLE_RATE * 1
  #samples = [].fill(0.0, 0, 0)
 #samples = generate_sample_data(1, 440.0, AMPLITUDE)

#D E F F E E F D C D D E C G F
	if !ARGV[0]
		puts "Please provide your text as an argument!"
		exit
	end

	morse = generate_morse_code(ARGV[0])
	p morse
	samples = generate_sequence_of_sample_data(morse)
 


  # Wrap the array of samples in a Buffer, so that it can be written to a Wave file
  # by the WaveFile gem. Since we generated samples with values between -1.0 and 1.0,
  # the sample format should be :float
  buffer = WaveFile::Buffer.new(samples, WaveFile::Format.new(:mono, :float, SAMPLE_RATE))

  # Write the Buffer containing our samples to a monophonic Wave file
  WaveFile::Writer.new(OUTPUT_FILENAME, WaveFile::Format.new(:mono, :pcm_16, SAMPLE_RATE)) do |writer|
    writer.write(buffer)
  end
  puts
  puts "File was saved as #{OUTPUT_FILENAME}"
end



def generate_sequence_of_sample_data(seq)
	# seq -> [[1, 440.0, 0.6], [1, 440.0, 0.6]]
	samples = generate_sample_data(seq[0][0], seq[0][1], seq[0][2])
	seq.size.times do |i|
		samples += generate_sample_data(seq[i][0], seq[i][1], seq[i][2])
	end
	return samples
end

# The dark heart of NanoSynth, the part that actually generates the audio data
def generate_sample_data(duration, frequency, amplitude)
	num_samples = (SAMPLE_RATE * duration).to_i
  position_in_period = 0.0
  position_in_period_delta = frequency / SAMPLE_RATE

  # Initialize an array of samples set to 0.0. Each sample will be replaced with
  # an actual value below.
  samples = [].fill(0.0, 0, num_samples)

  num_samples.times do |i|
    # Add next sample to sample list. The sample value is determined by
    # plugging position_in_period into the appropriate wave function.
    samples[i] = Math::sin(position_in_period * TWO_PI) * amplitude
    position_in_period += position_in_period_delta

    # Constrain the period between 0.0 and 1.0.
    # That is, keep looping and re-looping over the same period.
    if position_in_period >= 1.0
      position_in_period -= 1.0
    end
  end

  samples
end

main
