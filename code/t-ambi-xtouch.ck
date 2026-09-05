@import "c-midi.ck"

MidiDevice medi( 2 );

0 => medi.print;

// patchbay
Atmosphere2 grains( "../audio/yuo.wav", 1 )[8];
OrderGain2 faders( 0.0 )[8];
OrderGain2 sum( 1.0 / grains.size() ) => SAD2 sad => dac;
// reverb
// faders => Gain revSend( 0.0 )[9] => NRev reverb( 1.0 ) => dac;

float speaks[9][2];
for(int i; i < speaks.size(); i++)
{
   i*(360.0/8.0) => speaks[i][0]; // ring of 8 dividing 360 degrees
}

sad.placement(speaks);


for( int i; i < grains.size(); i++ ) 
{
	grains[i] => faders[i] => sad;
	grains[i].position( 1.0, grains[i].duration() * 2.0 );
}

int channelSwitch[8];
int channelLock[8];
float loopSpeed[8];

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
        	{
	            if ( ccval ) 1 => channelSwitch[ cc - 101 ];
	            else if( !ccval ) 0 => channelSwitch[ cc - 101 ];
        	}
        }
        // 1 - 9 are fader values, 
        else if( cc >= 1 && cc <= 9 )
        {
            // faders 1 - 8 are for voices
            if( cc <= 8 ) faders[ cc - 1 ].gain( midi2float( ccval ) );
            // fader 9 is main fader
            else dac.gain( midi2float( ccval ) );
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
                            ( grains[i].size() * midi2float( ccval ) ) + grains[i].size() => float n_size;
                            // if the value is 0, then we'll need to give it a boost 
                            if( grains[i].size() == 0 && ccval > 0 ) 0.05 +=> n_size;
                            // if it's really low, we're probably just continuously moving the knob to zero out the value
                            else if( n_size <= 0.05 ) 0.0 => n_size;
                            grains[i].size( n_size );
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
                            ( grains[i].randomSize() * midi2float( ccval ) ) + grains[i].randomSize() => float n_randomSize;
                            // if the value is 0, then we'll need to give it a boost 
                            if( grains[i].randomSize() == 0 && ccval > 0 ) 0.05 +=> n_randomSize;
                            // if it's really low, we're probably just continuously moving the knob to zero out the value
                            else if( n_randomSize <= 0.05 ) 0.0 => n_randomSize;
                            grains[i].randomSize( n_randomSize );
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
				grains[i].position( 0.0, 0::samp );
				grains[i].position( 1.0, grains[i].duration() * loopSpeed[i] );
			}
		}
		50::ms => now;
	}
}
