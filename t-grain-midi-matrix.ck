@import "c-midi.ck"
@import "c-xtouch.ck"

Assemblage grains( "voice_collage.wav", 8 )[8] => Gain fader( 0.0 )[8] => Dyno comp[2] => NRev rev( 0.125 )[2] => dac;

XTouch medi( 2 );

comp[0].compress();
comp[0].slopeBelow( 0.5 );

comp[1].compress();
comp[1].slopeBelow( 0.5 );

1 => int print;

while( true )
{
    medi => now; 
    for( int i; i < 8; i++ )
    {
        if( i <= 7 )
        {
            // set volume
            fader[i].gain( midiScale( medi.faderValues[i] ) );
            // size
            grains[i].size( midiScale( medi.parameter( i, 0 ) ) * 500.0 );
            if( print ) <<< "grain size: ", midiScale( medi.parameter( i, 0 ) ) * 500.0 >>>;
            // position
            grains[i].position( midiScale( medi.parameter( i, 1 ) ) );
            if( print ) <<< "position: ", midiScale( medi.parameter( i, 1 ) ) * grains[i].duration() >>>;
            // pitch
            grains[i].pitch( ( midiScale( medi.parameter( i, 2 ) ) * 4.0 ) );
            if( print ) <<< "pitch: ", ( midiScale( medi.parameter( i, 2 ) ) * 4.0 ) >>>;
            // spacer
            grains[i].spacer( ( midiScale( medi.parameter( i, 3 ) ) * 500::ms ) );
            if( print ) <<< "spacing: ", ( midiScale( medi.parameter( i, 3 ) ) * 500::ms ) >>>;
            // random size
            grains[i].randomSize( midiScale( medi.parameter( i, 4 ) ) * 500.0 );
            if( print ) <<< "rando size: ", midiScale( medi.parameter( i, 4 ) ) * 500.0 >>>;
            // random position
            grains[i].randomPosition( midiScale( medi.parameter( i, 5 ) ) * 5000.0 );
            if( print ) <<< "rando position: ", midiScale( medi.parameter( i, 5 ) ) * 5000.0 >>>;
            // random pitch
            grains[i].randomPitch( midiScale( medi.parameter( i, 6 ) ) * 8.0 );
            if( print ) <<< "rando pitch: ", midiScale( medi.parameter( i, 6 ) ) * 8.0 >>>;
        }
        else if( i == 8 )
        {
            dac.gain( midiScale( medi.parameter( i, 0 ) ) );
        }
        1::ms => now;
    }
}

fun float midiScale( int mid )
{
    return mid $ float / 127.0;
}