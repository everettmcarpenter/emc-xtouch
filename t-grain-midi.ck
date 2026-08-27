@import "c-midi.ck"
@import "c-xtouch.ck"

Assemblage grains( "voice_collage.wav", 8 )[8] => Gain fader( 0.0 )[8] => Dyno comp[2] => NRev rev( 0.125 )[2] => dac;

vec3 interpolators[8];

XTouch medi( 2 );

comp[0].compress();
comp[0].slopeBelow( 0.5 );

comp[1].compress();
comp[1].slopeBelow( 0.5 );

int lastGrain;

for( int i; i < fader.size(); i++ )
{
    interpolators[i].set( 1.0, 0.0, 0.05 * ( 1::second / 10::ms ) );
}

for( 1 => int i; i < 17; i++ ) { medi.sendCC( i, 1 ); }

// spork ~ vec3Interpolate( 10::ms );

while( true )
{
    medi => now; 
    if( medi.lastMsg() == medi.CC() )
    {
        medi.lastCC() => int cc;
        if( cc <= 8 && cc > 0 )
        {
            // interpolators[cc - 1].update( midiScale( medi.lastCCValue() ) );
            fader[cc -1].gain( midiScale( medi.faderValues[]) );
        }
        else if( cc == 9 )
        {
            dac.gain( midiScale( medi.lastCCValue() ) );
        }
        else if( cc == 10 )
        {
            grains[lastGrain].size( midiScale( medi.lastCCValue() ) * 500.0 );
            <<< "grain size: ", midiScale( medi.lastCCValue() ) * 500.0 >>>;
        }
        else if( cc == 11 )
        {
            grains[lastGrain].position( midiScale( medi.lastCCValue() ) );
            <<< "position: ", midiScale( medi.lastCCValue() ) * grains[lastGrain].duration() >>>;
        }
        else if( cc == 12 )
        {
            grains[lastGrain].pitch( ( midiScale( medi.lastCCValue() ) * 4.0 ) + 0.01 );
            <<< "pitch: ", ( midiScale( medi.lastCCValue() ) * 4.0 ) + 0.01 >>>;
        }
        else if( cc == 13 )
        {
            grains[lastGrain].spacer( ( midiScale( medi.lastCCValue() ) * 500::ms ) );
            <<< "spacing: ", ( midiScale( medi.lastCCValue() ) * 500::ms ) >>>;
        }
        else if( cc == 14 )
        {
            grains[lastGrain].randomSize( midiScale( medi.lastCCValue() ) * 500.0 );
            <<< "rando size: ", midiScale( medi.lastCCValue() ) * 500.0 >>>;
        }
        else if( cc == 15 )
        {
            grains[lastGrain].randomPosition( midiScale( medi.lastCCValue() ) * 5000.0 );
            <<< "rando position: ", midiScale( medi.lastCCValue() ) * 5000.0 >>>;
        }
        else if( cc == 16 )
        {
            grains[lastGrain].randomPitch( midiScale( medi.lastCCValue() ) * 8.0 );
            <<< "rando pitch: ", midiScale( medi.lastCCValue() ) * 8.0 >>>;
        }
        else if( cc >= 101 && cc <= 108 )
        {
            cc - 101 => lastGrain;
            <<< lastGrain >>>;
        }
    }
    else if( medi.lastMsg() == medi.NoteOn() )
    {
        medi.lastNoteOn() => int noteOn;
        if( noteOn >= 40 && noteOn <= 47 )
        {
            noteOn - 40 => lastGrain;
            <<< lastGrain >>>;
        }
    }
}

fun float midiScale( int mid )
{
    return mid $ float / 127.0;
}

fun void vec3Interpolate( dur to )
{
    while( true )
    {
        for( int i; i < interpolators.size(); i++ )
        {
            interpolators[i].interp( to ) => fader[i].gain;
        }
        to => now;
    }
}