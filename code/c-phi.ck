public class Phi extends Collage
{
    fun void Phi( string file, int num )
    {
        this.Collage( file, num );
        this.position( 1.0, this.duration() );
        1.0 => loopSpeed;
        spork ~ looper();
    }

    1 => int print;
    int channelSwitch;
    int channelLock;
    float loopSpeed;

    fun void d_size( int delta )
    {
        ( this.size() * midi2float( delta ) ) + this.size() => float n_size;

        // if the value is 0, then we'll need to give it a boost 
        if( this.size() == 0 && delta > 0 ) 
            0.05 +=> n_size;
        // if it's really low, we're probably just continuously moving the knob to zero out the value
        else if( n_size <= 0.05 ) 
            0.0 => n_size;

        this.size( n_size );
    	if( print ) <<< "grain size : ", this.size() >>>;
    }

    fun void d_randomSize( int delta )
    {
        ( this.randomSize() * midi2float( delta ) ) + this.randomSize() => float n_randomSize;
       
        // if the value is 0, then we'll need to give it a boost 
        if( this.randomSize() == 0 && delta > 0 ) 
            0.05 +=> n_randomSize;
        // if it's really low, we're probably just continuously moving the knob to zero out the value
        else if( n_randomSize <= 0.05 ) 
            0.0 => n_randomSize;
       
        this.randomSize( n_randomSize );
		if( print ) <<< "rando grain size : ", this.randomSize() >>>;
    }

    fun void d_position( int delta )
    {
        ( 0.025 * midi2float( delta ) ) + this.position() => float n_position;

        // if the value is 0, then we'll need to give it a boost 
        if( this.position() == 0 && delta > 0 ) 
            0.0001 +=> n_position;
        
        // clamp
        Math.clampf( n_position, 0.0, 1.0 ) => n_position;
        this.position( n_position );
        if( print ) <<< "grain position : ", this.position() >>>;
    }

    fun void d_randomPosition( int delta )
    {
        ( this.randomPosition() * midi2float( delta ) ) + this.randomPosition() => float n_randomPosition;
        
        // if the value is 0, then we'll need to give it a boost 
        if( this.randomPosition() == 0 && delta > 0 ) 
            0.05 +=> n_randomPosition;
        // if it's really low, we're probably just continuously moving the knob to zero out the value
        else if( n_randomPosition <= 0.05 ) 
            0.0 => n_randomPosition;

        this.randomPosition( n_randomPosition );
        if( print ) <<< "random grain position : ", this.randomPosition() >>>;
    }

    fun void d_pitch( int delta )
    {
        ( this.pitch() * midi2float( delta ) ) + this.pitch() => float n_pitch;

        // if the value is 0, then we'll need to give it a boost 
        if( this.pitch() == 0 && delta > 0 ) 
            0.05 +=> n_pitch;
        // if it's really low, we're probably just continuously moving the knob to zero out the value
        else if( n_pitch <= 0.05 ) 
            0.0 => n_pitch;

        this.pitch( n_pitch );
        if( print ) <<< "grain pitch : ", this.pitch() >>>;
    }

    fun void d_randomPitch( int delta )
    {
        ( this.randomPitch() * midi2float( delta ) ) + this.randomPitch() => float n_randomPitch;
        
        // if the value is 0, then we'll need to give it a boost 
        if( this.randomPitch() == 0 && delta > 0 ) 
            0.05 +=> n_randomPitch;
        // if it's really low, we're probably just continuously moving the knob to zero out the value
        else if( n_randomPitch <= 0.05 ) 
            0.0 => n_randomPitch;
        
        this.randomPitch( n_randomPitch );
        if( print ) <<< "random grain pitch : ", this.randomPitch() >>>;
    }

    fun void d_loopSpeed( int delta )
    {
        ( loopSpeed * midi2float( delta / 2 ) ) + loopSpeed => float n_loopSpeed;
        
        // if the value is 0, then we'll need to give it a boost 
        if( loopSpeed == 0 && delta > 0 ) 
            0.05 +=> n_loopSpeed;
        // if it's really low, we're probably just continuously moving the knob to zero out the value
        else if( n_loopSpeed <= 0.005 ) 
            0.0 =>  n_loopSpeed;

        if( n_loopSpeed < 0.0 ) 
            0.0 => n_loopSpeed;

        n_loopSpeed => loopSpeed;
        if( print ) <<< "playback speed : ", loopSpeed >>>;
    }

    fun void looper()
    {
        while( true )
        {
            if( this.position() == this.targetPosition() )
            {
                if( this.position() == 0.0 ) 
                    this.position( 1.0 );
                else if( this.position() == 1.0 ) 
                    this.position( 0.0, this.duration() * loopSpeed );
            }
            50::ms => now;
        }
    }

    fun float midi2float( int midi )
    {
        return midi / 127.0;
    }

    fun int getSwitch() { return channelSwitch; }

    fun int getLock() { return channelLock; }

    fun void setSwitch( int value ) { value % 2 => channelSwitch; }

    fun void setLock( int value ) { value % 2 => channelLock; }

    fun void flipSwitch()
    {
        ++channelSwitch % 2 => channelSwitch;
    }

    fun void flipLock()
    {
        ++channelSwitch % 2 => channelLock;
    }

    fun void switchChannel( int state )
    {
        if( state ) 1 => channelSwitch;
        else 0 => channelSwitch;
    } 
}
