@import "c-midi.ck"

public class XTouch extends MidiDevice
{
    int faderOn[9]; // which faders are being touched?
    int lastCCValue; int lastCCNum;
    int lastNoteOn; int lastNoteOff;
    int lastVelocity;

    int lastMessageType;

    fun void XTouch()
    {
        // open the device
        if( !midin.open( 0 ) && !midout.open( 0 ) ) me.exit();
        // print out device that was opened
        <<< "MIDI device:", midin.num(), " -> ", midin.name() >>>;
            
        spork ~ update();
    }

    fun void XTouch( int device )
    {
        // open the device
        if( !midin.open( device ) && !midout.open( device ) ) me.exit();

        // print out device that was opened
        <<< "MIDI device:", midin.num(), " -> ", midin.name() >>>;
         
        spork ~ update();
    }

    fun void update()
    {
        while( true )
        {
            midin => now;
            while( midin.recv( midmsg ) )
            {
                midmsg.data1 => lastMsgType;
                
                if( lastMsgType == this.CC() )
                {
                    midmsg.data2 => lastCCNum;
                    midmsg.data3 => lastCCVal;
                }
                else if( lastMsgType == this.NoteOn() )
                {
                    midmsg.data2 => lastNoteOn;
                    midmsg.data3 => lastVelocity;
                }
                else if( lastMsgType == this.NoteOff() )
                {
                    midmsg.data2 => lastNoteOff;
                    midmsg.data3 => lastVelocity;
                }

                if( midmsg.data1 == this.CC() )
                {
                    if( lastCCNum >= 101 && lastCCNum <= 109 ) // these are the CCs send when a fader is touched!
                    {   
                        if( lastCCVal ) 1 => faderOn[lastCCNum - 101]; // if the value was non-zero, the fader was touched
                        else 0 => faderOn[lastCCNum - 101]; // if the value was 0, then it was released

                        this.faderMovement() => lastMessageType;
                    }
                }
            }
        }
    }

}

public class XTouch extends MidiDevice
{
    int faderOn[9]; // which faders are being touched?
    int faderValues[9];
    int channelValues[9][16]; // we have nine faders which select 9 channels which have 16 knobs each
    int ccValues[16];
    int deltaCCValues[16];
    int deltaChannelValues[9][16]; // the difference between channelValues and the values that came before it
    int lastParameter; // the last knob TURNT
    int lastFader; // the last fader TOUCHED
    int lastMessageType;
	1 => int mode; // mode 0 is knobs are 0-127 and mode 1 is knobs are relative
    1 => int channelTouch; // are we applying the changes of a knob to all channels
    1 => int relativeDelta; // are knob changes applied to all channels absolutely, or are they relative to the current value?
    0 => print;
    
    fun void XTouch()
    {
        // open the device
        if( !midin.open( 0 ) && !midout.open( 0 ) ) me.exit();
        // print out device that was opened
        <<< "MIDI device:", midin.num(), " -> ", midin.name() >>>;
            
        spork ~ update();
    }

    fun void XTouch( int device )
    {
        // open the device
        if( !midin.open( device ) && !midout.open( device ) ) me.exit();

        // print out device that was opened
        <<< "MIDI device:", midin.num(), " -> ", midin.name() >>>;
         
        spork ~ update();
    }

    fun void update()
    {
        while( true )
        {
            midin => now;
            while( midin.recv( midmsg ) )
            {
                if( midmsg.data1 == 176 )
                {
                    midmsg.data1 => lastMsgType;
                    midmsg.data2 - lastCCVal => deltaCCVal; 
                    midmsg.data2 => lastCCNum;
                    midmsg.data3 => lastCCVal;

                    if( lastCCNum >= 101 && lastCCNum <= 109 ) // these are the CCs send when a fader is touched!
                    {   
                        if( lastCCVal ) 
                        {
                            1 => faderOn[lastCCNum - 101]; // if the value was non-zero, the fader was touched
                            lastCCNum - 101 => lastFader; // the last fader touched . . . 
                        }
                        else 0 => faderOn[lastCCNum - 101]; // if the value was 0, then it was released
                        faderMovement() => lastMessageType;
                    }
                    else if( lastCCNum >= 10 && lastCCNum <= 25 ) // attribute any changes on these CCs (knobs) to a fader channel
                    {
                        lastCCVal - ccValues[lastCCNum - 10] => deltaCCValues[lastCCNum - 10];
                        lastCCVal => ccValues[lastCCNum - 10];
                        if( channelTouch ) // are we attributing knob movements to all channels?
                        { 
                            for( int i; i < faderOn.size(); i++ ) 
                            {
                                if( faderOn[i] ) // we'll apply this parameter change to all faders being touched
                                {
                                    if( relativeDelta )
                                    {
                                        if( print ) printMatrix();
                                        if( mode )
                                        {
                                        	( lastCCVal - 64 ) +=> channelValues[i][lastCCNum - 10];
                                        	<<< channelValues[i][lastCCNum - 10] >>>;
                                        } 
                                        else 
                                        {
                                        	deltaCCValues[lastCCNum - 10] +=> channelValues[i][lastCCNum - 10];
                                        	Std.clamp( channelValues[i][lastCCNum - 10], 0, 127 ) => channelValues[i][lastCCNum - 10];
                                       	}
                                    }
                                    else
                                    {
                                        lastCCVal => channelValues[i][lastCCNum - 10];
                                    }
                                }
                            }
                        }
                        else // else we'll apply the knob turn to the last fader 
                        {
                            lastCCVal - channelValues[lastFader][lastCCNum - 10] => deltaChannelValues[lastFader][lastCCNum - 10];
                            if( relativeDelta )
                            {
                                deltaChannelValues[lastFader][lastCCNum - 10] +=> channelValues[lastFader][lastCCNum - 10];
                                Std.clamp( channelValues[lastFader][lastCCNum - 10], 0, 127 ) => channelValues[lastFader][lastCCNum - 10];
                            }
                            else
                            {
                                lastCCVal => channelValues[lastFader][lastCCNum - 10];
                            }
                        }
                        lastCCNum - 10 => lastParameter; 
                        knobMovement() => lastMessageType;
                    }
                    else if( lastCCNum >= 1 && lastCCNum <= 9 ) // these are the CCs which are sent when faders are changed
                    {
                        lastCCVal => faderValues[lastCCNum - 1]; // and it's fader position is...
                    }

                    if( print ) <<< "CC: ", lastCCNum, lastCCVal >>>;
                }
                else if( midmsg.data1 == 144 )
                {
                    midmsg.data1 => lastMsgType;
                    midmsg.data2 => lastNoteKeyOn;
                    midmsg.data3 => lastNoteOnVelocity;
                    if( print ) <<< "Note on: ", lastNoteKeyOn, lastNoteOnVelocity >>>;
                }
                else if( midmsg.data1 == 128 )
                {
                    midmsg.data1 => lastMsgType;
                    midmsg.data2 => lastNoteKeyOff;
                    midmsg.data3 => lastNoteOffVelocity;
                    if( print ) <<< "Note off: ", lastNoteKeyOff, lastNoteOffVelocity >>>;
                }
                this.broadcast(); // signal to everyone
            }
        }
    }

    // using the last fader selected, send it's knob values to the device to update
    fun void updateKnobs()
    {
        for( int i; i < channelValues[0].size(); i++ )
        {
            this.sendCC( i + 26, channelValues[lastCCNum - 101][i] );
        }
    }

    // print the matrix
    fun void printMatrix()
    {
        for( int i; i < channelValues.size(); i++ )
        {
            cherr <= "Row: " <= i <= " ";
            for( int j; j < channelValues[i].size(); j++ )
            {
                cherr <= channelValues[i][j] <= " ";
            }
            cherr <= IO.nl();
        }
    }

    fun int parameter( int channel, int param )
    {
        return channelValues[channel][param];
    }

    fun int delta( int channel, int param )
    {
        return deltaChannelValues[channel][param];
    }

    fun int faderMovement() { return 1; }
     
    fun int knobMovement() { return 2; }

}
