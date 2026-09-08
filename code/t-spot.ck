@import "c-midi.ck"
@import "c-spot.ck"

8 => int GRAIN_CHANNELS;

// midi 
MidiDevice medi( 17, 18 );
0 => medi.print;

// patchbay
Spot grains( "../audio/440.wav", 1 )[ GRAIN_CHANNELS ];
OrderGain2 faders( 1.0 )[ GRAIN_CHANNELS ];
OrderGain2 sum( 0.5 ) => SAD2 sad;

// reverb
// faders => Gain revSend( 0.0 )[9] => NRev reverb( 1.0 ) => dac;
for(int i; i < sad.channels(); i++) sad.chan(i) => dac.chan(i);

float speaks[9][2];
for(int i; i < speaks.size(); i++)
{
   i*(360.0/8.0) => speaks[i][0]; // ring of 8 dividing 360 degrees
}

sad.placement( speaks );

for( int i; i < grains.size(); i++ ) 
{
	grains[i] => faders[i] => sum;
	grains[i].position( 1.0, grains[i].duration() * 2.0 );
}

int channelSwitch[ GRAIN_CHANNELS ];
int channelLock[ GRAIN_CHANNELS ];
float loopSpeed[ GRAIN_CHANNELS ];

/*
    TODO - since we have multiple channels, it may be worth investigating using for each loops rather than typical for
           this way, when we need to call updateGrainSize or something similar, we can call a function whose arguments
           contain a reference to a grain and the delta, that way we don't have to index check.
           we could also create a meta-class of the grains which contain updateGrainSize and similar to only pass the deltas
           completely removing the need for bounds checking and fully contains the parameters within a block.
           the only issue with utilizing a meta class is that chugraphs are not multichannel and thus we would use some workaround for it.  
           another issue is that things like channelLock and channelSwitch would need to be integrated into a meta class, thus we NEED a meta class 
           to eliminate bounds checking ( not impossible )
*/

while( true )
{
    medi => now;

    if( medi.lastMsg() == medi.CC() )
    {
        medi.lastCC() => int cc;
        medi.lastCCValue() => int ccval;
        // 101 - 108 are fader "on" messages
        if( cc >= 101 && cc <= 108 )
        {
        	// if the channel isn't locked, we can modify the state
        	if( !channelLock[ cc - 101 ] ) 
                grains[ cc - 101 ].switchChannel( ccval );
        }
        // 1 - 9 are fader values, for layer A
        else if( cc >= 1 && cc <= 9 )
        {
            // faders 1 - 8 are for voices
            if( cc <= 8 ) 
                updateChannelFader( cc - 1, ccval );
            // fader 9 is main fader
            else 
                updateOutFader( ccval );
        }
        // 10 - 25 are knobs
        else if( cc >= 10 && cc <= 25 )
        {
            // top row knobs, which return delta movement
            if( cc <= 17 )
            {
                ccval - 64 => ccval;
                if( cc == 10 )
                {
                    for( Spot s : grains )
                    {
                        if( s.getSwitch() )
                            s.d_size( ccval );
                    }
                }
                else if( cc == 11 )
                {
                    for( Spot s : grains )
                    {
                        if( s.getSwitch() )
                            s.d_randomSize( ccval );
                    }
                }
                else if( cc == 12 )
                {
                    for( Spot s : grains )
                    {
                        if( s.getSwitch() )
                            s.d_position( ccval );
                    }
                }
                else if( cc == 13 )
                {
                    for( Spot s : grains )
                    {
                        if( s.getSwitch() )
                            s.d_randomPosition( ccval );
                    }
                }
                else if( cc == 14 )
                {
                    for( Spot s : grains )
                    {
                        if( s.getSwitch() )
                            s.d_pitch( ccval );
                    }
                }
                else if( cc == 15 )
                {
                    for( Spot s : grains )
                    {
                        if( s.getSwitch() )
                            s.d_randomPitch( ccval );
                    }
                }
                else if( cc == 16 )
                {
                    for( Spot s : grains )
                    {
                        if( s.getSwitch() )
                            s.d_loopSpeed( ccval );
                    }
                }
            }
        }
    }
	else if( medi.lastMsg() == medi.NoteOn() )
	{
		medi.lastNoteOn() => int note;
        medi.lastOnVelocity() => int vel;

		// swap state and lock
        if( note >= 40 && note <= 47 )
        {
            grains[ note - 40 ].flipSwitch();
            grains[ note - 40 ].flipLock();

        	medi.noteOn( note - 15, 1 );
        }
        else if( note == 48 )
        {	
        	// swap em all
        	for( Spot s : grains ) 
        	{
        		s.setSwitch( 1 );
                s.setLock( 1 );
       		}
        }
        else if( note == 6 )
        {
        	for( Spot s : grains )
        	{
        		if( s.getSwitch() )
        		{
        			s.targetPosition() - s.position() => float distance;
					s.position( 1.0, s.duration() * distance * s.loopSpeed );
					<<< "resumed movement" >>>;		
        		}
        	}
        }
	} 
	else if( medi.lastMsg() == medi.NoteOff() )
	{
		medi.lastNoteOff() => int note;
    	medi.lastOffVelocity() => int vel;

		// you can hold the main fader button to edit them all momentarily
		if( note == 48 )
		{	
			// unlock em all
			for( Spot s : grains ) 
			{
				s.setSwitch( 0 );
                s.setLock( 0 );
			}
		}
	} 
}

fun float midi2float( int midi )
{
    return midi / 127.0;
}

fun void updateChannelFader( int channel, int midiValue )
{
    faders[ channel ].gain( midi2float( midiValue ) ); // we should find a way to make this logarithmic
}

fun void updateOutFader( int midiValue )
{
    sum.gain( midi2float( midiValue ) );
}