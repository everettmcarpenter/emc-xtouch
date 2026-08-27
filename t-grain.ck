@import "c-midi.ck"
@import "c-xtouch.ck"
@import "Rec.ck"

Assemblage grains( "Leeds-Bells.wav", 8 )[8] => Gain fader( 0.0 )[8] => Dyno comp[2] => NRev rev( 0.125 )[2] => dac;

Rec.auto();

XTouch medi( 2 );

comp[0].compress();
comp[0].slopeBelow( 0.5 );

comp[1].compress();
comp[1].slopeBelow( 0.5 );

1 => int print;

while( true )
{
    medi => now; 
    if( medi.lastMessageType == medi.faderMovement() )
    {
        for( int i; i < 8; i++ )
       	{
       		 fader[i].gain( midiScale( medi.faderValues[i] ) );
       	}
       	// main fader
        dac.gain( midiScale( medi.faderValues[8] ) );
    }
    else if( medi.lastMessageType == medi.knobMovement() )
    {
        for( int i; i < 8; i++ )
        {
            if( medi.faderOn[i] )
            {
                <<< medi.lastParameter >>>;
                if( medi.lastParameter == 0 )
                {
                    // size
                    grains[i].size( midiScale( Math.abs( medi.parameter( i, 0 ) ) * 500.0 ) );
                    if( print ) <<< "grain size: ", midiScale( Math.abs( medi.parameter( i, 0 ) ) * 500.0 ) >>>;
                }
                else if( medi.lastParameter == 1 )
                {
                    // position
                    grains[i].position( 0.01 * midiScale( Math.abs( medi.parameter( i, 1 ) ) ) );
                    if( print ) <<< "position: ", midiScale( Math.abs( medi.parameter( i, 1 ) ) ) * grains[i].duration() >>>;
                }
                else if( medi.lastParameter == 2 )
                {
                    // pitch
                    grains[i].pitch( ( midiScale( Math.abs( medi.parameter( i, 2 ) ) * 4.0 ) ) );
                    if( print ) <<< "pitch: ", ( midiScale( Math.abs( medi.parameter( i, 2 ) ) * 4.0 ) ) >>>;
                }
                else if( medi.lastParameter == 3 )
                {
                    // spacer
                    grains[i].spacer( ( midiScale( Math.abs( medi.parameter( i, 3 ) ) ) * 500::ms ) );
                    if( print ) <<< "spacing: ", ( ( midiScale( Math.abs( medi.parameter( i, 3 ) ) ) * 500::ms ) ) >>>;
                }
                else if( medi.lastParameter == 4 )
                {
                    // random size
                    grains[i].randomSize( midiScale( Math.abs( medi.parameter( i, 4 ) ) * 500.0 ) );
                    if( print ) <<< "rando size: ", midiScale( Math.abs( medi.parameter( i, 4 ) ) * 500.0 ) >>>;
                }
                else if( medi.lastParameter == 5 )
                {
                    // random position
                    grains[i].randomPosition( midiScale( Math.abs( medi.parameter( i, 5 ) ) * 5000.0 ) );
                    if( print ) <<< "rando position: ", midiScale( Math.abs( medi.parameter( i, 5 ) ) * 5000.0 ) >>>;
                }
                else if( medi.lastParameter == 6 )
                {
                    // random pitch
                    grains[i].randomPitch( midiScale( Math.abs( medi.parameter( i, 6 ) ) * 8.0 ) );
                    if( print ) <<< "rando pitch: ", midiScale( Math.abs( medi.parameter( i, 6 ) ) ) * 8.0 >>>;
                }
                /*
                else if( medi.lastParameter == 7 )
                {
                    // random pitch
                    grains[i].randomSpace( midiScale( medi.parameter( i, 7 ) ) * 500::ms );
                    if( print ) <<< "rando space: ", midiScale( medi.parameter( i, 7 ) ) * 500::ms >>>;
                }
                */
            }
        }
    }
    1::ms => now;
}

fun float midiScale( int mid )
{
    return mid $ float / 127.0;
}

fun float midiScale( float mid )
{
    return mid $ float / 127.0;
}
