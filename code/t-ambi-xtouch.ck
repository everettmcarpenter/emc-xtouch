@import "c-midi.ck"

8 => int GRAIN_CHANNELS;

// midi 
MidiDevice medi( 17, 18 );
0 => medi.print;

// patchbay
Atmosphere2 grains( "../audio/440.wav", 1 )[ GRAIN_CHANNELS ];
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

sad.placement(speaks);

for( int i; i < grains.size(); i++ ) 
{
	grains[i] => faders[i] => sum;
	grains[i].position( 1.0, grains[i].duration() * 2.0 );
}

int channelSwitch[ GRAIN_CHANNELS ];
int channelLock[ GRAIN_CHANNELS ];
float loopSpeed[ GRAIN_CHANNELS ];

spork ~ looper();


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
                updateChannelState( cc - 101, ccval );
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
                    for( int i; i < grains.size(); i++ )
                    {
                        if( channelSwitch[i] )
                        {
                            updateGrainSize( i, ccval );
                            <<< "grain size : ", grains[i].size() >>>;
                        }
                    }
                }
                else if( cc == 11 )
                {
                    for( int i; i < grains.size(); i++ )
                    {
                        if( channelSwitch[i] )
                        {
                            updateRandomSize( i, ccval );
                            <<< "random grain size : ", grains[i].randomSize() >>>;
                        }
                    }
                }
                else if( cc == 12 )
                {
                    for( int i; i < grains.size(); i++ )
                    {
                        if( channelSwitch[i] )
                        {
                            ( 0.025 * midi2float( ccval ) ) + grains[i].position() => float n_position;
                            // if the value is 0, then we'll need to give it a boost 
                            if( grains[i].position() == 0 && ccval > 0 ) 0.0001 +=> n_position;
                            // clamp
                            Math.clampf( n_position, 0.0, 1.0 ) => n_position;
                            grains[i].position( n_position );
                            <<< "grain position : ", grains[i].position() >>>;
                        }
                    }
                }
                else if( cc == 13 )
                {
                    for( int i; i < grains.size(); i++ )
                    {
                        if( channelSwitch[i] )
                        {
                            ( grains[i].randomPosition() * midi2float( ccval ) ) + grains[i].randomPosition() => float n_randomPosition;
                            // if the value is 0, then we'll need to give it a boost 
                            if( grains[i].randomPosition() == 0 && ccval > 0 ) 0.05 +=> n_randomPosition;
                            // if it's really low, we're probably just continuously moving the knob to zero out the value
                            else if( n_randomPosition <= 0.05 ) 0.0 => n_randomPosition;
                            grains[i].randomPosition( n_randomPosition );
                            <<< "random grain position : ", grains[i].randomPosition() >>>;
                        }
                    }
                }
                else if( cc == 14 )
                {
                    for( int i; i < grains.size(); i++ )
                    {
                        if( channelSwitch[i] )
                        {
                            ( grains[i].pitch() * midi2float( ccval ) ) + grains[i].pitch() => float n_pitch;
                            // if the value is 0, then we'll need to give it a boost 
                            if( grains[i].pitch() == 0 && ccval > 0 ) 0.05 +=> n_pitch;
                            // if it's really low, we're probably just continuously moving the knob to zero out the value
                            else if( n_pitch <= 0.05 ) 0.0 => n_pitch;
                            grains[i].pitch( n_pitch );
                            <<< "grain pitch : ", grains[i].pitch() >>>;
                        }
                    }
                }
                else if( cc == 15 )
                {
                    for( int i; i < grains.size(); i++ )
                    {
                        if( channelSwitch[i] )
                        {
                            ( grains[i].randomPitch() * midi2float( ccval ) ) + grains[i].randomPitch() => float n_randomPitch;
                            // if the value is 0, then we'll need to give it a boost 
                            if( grains[i].randomPitch() == 0 && ccval > 0 ) 0.05 +=> n_randomPitch;
                            // if it's really low, we're probably just continuously moving the knob to zero out the value
                            else if( n_randomPitch <= 0.05 ) 0.0 => n_randomPitch;
                            grains[i].randomPitch( n_randomPitch );
                            <<< "random grain pitch : ", grains[i].randomPitch() >>>;
                        }
                    }
                }
                else if( cc == 16 )
                {
                    for( int i; i < grains.size(); i++ )
                    {
                        if( channelSwitch[i] )
                        {
                            ( loopSpeed[i] * midi2float( ccval / 2 ) ) + loopSpeed[i] => float n_loopSpeed;
                            // if the value is 0, then we'll need to give it a boost 
                            if( loopSpeed[i] == 0 && ccval > 0 ) 0.05 +=> n_loopSpeed;
                            // if it's really low, we're probably just continuously moving the knob to zero out the value
                            else if( n_loopSpeed <= 0.005 ) 0.0 =>  n_loopSpeed;
                            if( n_loopSpeed < 0.0 ) 0.0 => n_loopSpeed;
                            n_loopSpeed => loopSpeed[i];
                            <<< "playback speed : ", loopSpeed[i] >>>;
                        }
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
        	++channelSwitch[ note - 40 ] % 2 => channelSwitch[ note - 40 ];
        	++channelLock[ note - 40 ] % 2 => channelLock[ note - 40 ];
        	medi.noteOn( note - 15, 1 );
        }
        else if( note == 48 )
        {	
        	// swap em all
        	for( int i; i < channelSwitch.size(); i++ ) 
        	{
        		1 => channelSwitch[i] => channelLock[i];
        		medi.noteOn( i + 25, 2 );
        		<<< "note on: ", i + 25, 2 >>>;
       		}
        }
        else if( note == 6 )
        {
        	for( int i; i < channelSwitch.size(); i++ )
        	{
        		if( channelSwitch[i] )
        		{
        			1.0 - grains[i].position() => float distance;
					grains[i].position( 1.0, grains[i].duration() * distance * loopSpeed[i] );
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
			for( int i; i < channelSwitch.size(); i++ ) 
			{
				0 => channelSwitch[i] => channelLock[i];
				medi.noteOff( i + 25, 0 ); 
			}
		}
	} 
}

fun float midi2float( int midi )
{
    return midi / 127.0;
}

fun void looper()
{
	for( int i; i < grains.size(); i++ )
	{
		grains[i].position( 1.0, grains[i].duration() );
		1.0 => loopSpeed[i];
	}
	while( true )
	{
		for( int i; i < grains.size(); i++ )
		{
			if( grains[i].position() == 1.0 )
			{
				grains[i].position( 0.0 );
				10::samp => now;
				grains[i].position( 1.0, grains[i].duration() * loopSpeed[i] );
			}
		}
		50::ms => now;
	}
}

fun void updateChannelState( int channel, int state )
{
    if( state ) 1 => channelSwitch[ channel ];
    else 0 => channelSwitch[ channel ];
}

fun void updateChannelFader( int channel, int midiValue )
{
    faders[ channel ].gain( midi2float( midiValue ) ); // we should find a way to make this logarithmic
}

fun void updateOutFader( int midiValue )
{
    sum.gain( midi2float( midiValue ) );
}

fun void updateGrainSize( int whichGrain, int delta )
{
    ( grains[ whichGrain ].size() * midi2float( delta ) ) + grains[ whichGrain ].size() => float n_size;
    // if the value is 0, then we'll need to give it a boost 
    if( grains[ whichGrain ].size() == 0 && delta > 0 ) 0.05 +=> n_size;
    // if it's really low, we're probably just continuously moving the knob to zero out the value
    else if( n_size <= 0.05 ) 0.0 => n_size;
    grains[ whichGrain ].size( n_size );
}

fun void updateRandomSize( int whichGrain, int delta )
{
    ( grains[ whichGrain ].randomSize() * midi2float( delta ) ) + grains[ whichGrain ].randomSize() => float n_randomSize;
    // if the value is 0, then we'll need to give it a boost 
    if( grains[ whichGrain ].randomSize() == 0 && delta > 0 ) 0.05 +=> n_randomSize;
    // if it's really low, we're probably just continuously moving the knob to zero out the value
    else if( n_randomSize <= 0.05 ) 0.0 => n_randomSize;
    grains[ whichGrain ].randomSize( n_randomSize );
}

fun void updateGrainSize( Atmosphere2 @ grain, int delta )
{
    ( grain.size() * midi2float( delta ) ) + grain.size() => float n_size;
    // if the value is 0, then we'll need to give it a boost 
    if( grain.size() == 0 && delta > 0 ) 0.05 +=> n_size;
    // if it's really low, we're probably just continuously moving the knob to zero out the value
    else if( n_size <= 0.05 ) 0.0 => n_size;
    grain.size( n_size );
}