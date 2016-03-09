class MyNotify is MDBNotify
  let env: Env
  new create( env': Env ) =>
    env = env'

  fun ref fail( dbe: MDBEnvironment, code: I32, msg: String ) =>
    env.out.print("Error: " + msg)

actor Main

  new create( env: Env ) =>
      var dbe: MDBEnvironment = MDBEnvironment.create( MyNotify.create(env) )
    env.out.print("Environment created")
    dbe.open( "lmdb.mdb", 0, 0b111000000 )
    env.out.print(" Files opened")

    let txn = dbe.begin( 0 )
    env.out.print(" Txn started")

    let dbi = txn.open( None, 0 )
    env.out.print(" DB opened")

    dbi.update( s2a("Orange"), s2a("fruit"))
    env.out.print(" Record written")

    let result = dbi( s2a("Orange") )
    env.out.print( " Read back " + result.size().string() + " bytes" )
    
    txn.commit()
    env.out.print(" Txn commited")
    dbe.close()		    

  fun ref a2s( a: Array[U8] val ) : String ref =>
    var s: String ref = recover ref String.create( a.size() ) end
    var n: USize = 0
    while n < a.size() do
	    try s(n) = a(n) end
	    n = n + 1
    end
    s
  
  fun ref s2a( s: String val ): Array[U8] =>
    recover iso
      var a: Array[U8] = Array[U8].create( s.size() )
      var n: USize = 0
      while n < s.size() do
	try a(n) = s(n) end
        n = n + 1
      end   
      a
      end	  