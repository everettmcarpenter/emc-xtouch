public class MidiDevice extends Event
{
    MidiIn midin; // recv midi
    MidiOut midout; // send midi 
    MidiMsg midmsg; // midi unravel
    0 => int print;

    fun void MidiDevice()
    {
        // open the device
        if( !midin.open( 0 ) && !midout.open( 0 ) ) me.exit();
        // print out device that was opened
        <<< "MIDI device:", midin.num(), " -> ", midin.name() >>>;
            
        spork ~ update();
    }

    fun void MidiDevice( int device )
    {
        // open the device
        if( !midin.open( device ) && !midout.open( device ) ) me.exit();

        // print out device that was opened
        <<< "MIDI device:", midin.num(), " -> ", midin.name() >>>;
         
        spork ~ update();
    }

    // last cc and note
    int lastCCNum; int lastNoteKeyOn; int lastNoteKeyOff; 
    int lastNoteOnVelocity; int lastNoteOffVelocity;
    int lastMsgType; // 176 == cc, 144 == note on, 128 == note off
    // the value of the cc
    int lastCCVal;

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
                    midmsg.data2 => lastCCNum;
                    midmsg.data3 => lastCCVal;
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
                    if( print ) <<< "Note on: ", lastNoteKeyOff, lastNoteOffVelocity >>>;
                }
                this.broadcast(); // signal to everyone
            }
        }
    }

    fun void sendCC( int ccNum, int value )
    {
        this.midout.controlChange( 1, ccNum, value );
    }

    fun int CC()
    {
        return 176;
    }

    fun int NoteOn()
    {
        return 144;
    }

    fun int NoteOff()
    {
        return 128;
    }

    fun int lastMsg()
    {
        return lastMsgType;
    }

    fun int lastNoteOn()
    {
        return lastNoteKeyOn;
    }

    fun int lastNoteOff()
    {
        return lastNoteKeyOff;
    }

    fun int lastCC()
    {
        return lastCCNum;
    }

    fun int lastCCValue()
    {
        return lastCCVal;
    }
}