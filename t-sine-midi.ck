@import "c-midi.ck"

SinOsc sin[8] => Gain fader( 0.0 )[8] => Dyno comp[2] => NRev rev( 0.125 )[2] => dac;

vec3 interpolators[8];

MidiDevice medi( 2 );

comp[0].compress();
comp[0].slopeBelow( 0.5 );

comp[1].compress();
comp[1].slopeBelow( 0.5 );

for( int i; i < sin.size(); i++ )
{
    sin[i].freq( ( Math.randomf() * 1200.0 ) + 50.0 );
    interpolators[i].set( 1.0, 0.0, 0.05 * ( 1::second / 10::ms ) );
}

for( 1 => int i; i < 17; i++ ) { medi.sendCC( i, 1 ); }

spork ~ vec3Interpolate( 10::ms );

while( true )
{
    medi => now; 
    if( medi.lastMsg() == medi.CC() )
    {
        medi.lastCC() => int cc;
        if( cc <= 8 && cc > 0 )
        {
            interpolators[cc - 1].update( midiScale( medi.lastCCValue() ) );
        }
        else if( cc == 9 )
        {
            dac.gain( midiScale( medi.lastCCValue() ) );
        }
        else if( cc >= 100 && cc <= 107 && medi.lastCCValue() == 127 )
        {
            sin[cc - 101].freq( ( Math.randomf() * 1200.0 ) + 50.0 );
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