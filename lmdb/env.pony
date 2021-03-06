// Library major version 0.9.70, released December 19, 2015.

use "debug"
use "lib:lmdb"  // Link against the lmdb library.

// A whole lot of FFI calls

use @mdb_env_create[Stat]( env: Pointer[Pointer[MDBenv]] )
use @mdb_version[None]( major: Pointer[USize],
	minor: Pointer[USize], patch: Pointer[USize] )
use @mdb_env_open[Stat]( env: Pointer[MDBenv] tag,
    path: Pointer[U8] tag, flags: FlagMask, mode: USize )
use @mdb_env_copy[Stat]( env: Pointer[MDBenv], path: Pointer[U8] tag )
use @mdb_env_copy2[Stat]( env: Pointer[MDBenv], path: Pointer[U8] tag,
	flags: FlagMask )
use @mdb_env_stat[None]( env: Pointer[MDBenv], stat: MDBstat )
use @mdb_env_info[Stat]( env: Pointer[MDBenv] tag, stat: Pointer[MDBinfo] )
use @mdb_env_sync[Stat]( env: Pointer[MDBenv], force: FlagMask )
use @mdb_env_close[None]( env: Pointer[MDBenv] )
use @mdb_env_set_flags[Stat]( env: Pointer[MDBenv], flags: FlagMask, onoff: U32)
use @mdb_env_get_flags[Stat]( env: Pointer[MDBenv], flags: Pointer[FlagMask] )
use @mdb_env_get_path[Stat]( env: Pointer[MDBenv] tag,
	path: Pointer[Pointer[U8] val] )
use @mdb_env_set_mapsize[Stat]( env:Pointer[MDBenv], size: USize )
use @mdb_env_set_maxreaders[Stat]( env: Pointer[MDBenv] tag, count: USize )
use @mdb_env_get_maxreaders[Stat]( env: Pointer[MDBenv] tag, count: Pointer[USize] )
use @mdb_env_set_maxdbs[Stat]( env: Pointer[MDBenv], count: USize )
use @mdb_env_get_maxkeysize[USize]( enc: Pointer[MDBenv] )
use @mdb_env_set_userctx[Stat]( env: Pointer[MDBenv], ctx: Pointer[Any] )
use @mdb_env_get_userctx[ Pointer[Any] ]( env: Pointer[MDBenv] )
use @mdb_txn_begin[Stat]( env: Pointer[MDBenv],
	parent: Pointer[MDBtxn] tag,
	flags: FlagMask,
	txn: Pointer[Pointer[MDBtxn]] )
use @mdb_strerror[Pointer[U8]]( err: Stat )

// Some value sizes that might need to change.
type Stat is I32       // Status returns from the FFI calls
type FlagMask is U32   // Bitmasks for options on some calls

// Opaque structures for actual LMDB handles.
primitive MDBenv  // The overall LMDB Environment
primitive MDBtxn  // A transaction within the environment
primitive MDBdbi  // A database within the environment
primitive MDBcur  // A cursor for sequential operations

// Error codes returned from most operations
primitive MDBerror
  fun success(): I32 => 0	/**	Successful result */
  fun keyexist(): I32 => -30799	/** key/data pair already exists */
  fun notfound(): I32 => -30798	/** key/data pair not found (EOF) */
  fun page_notfound(): I32 => -30797	/** Requested page not found - this usually indicates corruption */
  fun corrupted(): I32 => -30796	/** Located page was wrong type */
  fun panic	(): I32 => -30795	/** Update of meta page failed or environment had fatal error */
  fun version_mismatch(): I32 => -30794	/** Environment version mismatch */
  fun invalid(): I32 => -30793	/** File is not a valid LMDB file */
  fun map_full(): I32 => -30792	/** Environment mapsize reached */
  fun dbs_full(): I32 => -30791	/** Environment maxdbs reached */
  fun readers_full(): I32 => -30790	/** Environment maxreaders reached */
  fun tls_full(): I32 => -30789	/** Too many TLS keys in use - Windows only */
  fun txn_full(): I32 => -30788	/** Txn has too many dirty pages */
  fun cursor_full(): I32 => -30787	/** Cursor stack too deep - internal error */
  fun page_full(): I32 => -30786	/** Page has not enough space - internal error */
  fun map_resized(): I32 => -30785	/** Database contents grew beyond environment mapsize */
  fun incompatible(): I32 => -30784	/** Operation and DB incompatible,
	  or DB type changed. This can mean:
	  * The operation expects an #MDB_DUPSORT / #MDB_DUPFIXED database.
	  * Opening a named DB when the unnamed DB has #MDB_DUPSORT / #MDB_INTEGERKEY.
	  * Accessing a data record as a database, or vice versa.
	  * The database was dropped and recreated with different flags. */

  fun bad_rslot	(): I32 => -30783 /** Invalid reuse of reader locktable slot */
  fun bad_txn(): I32 => -30782	/** Transaction must abort, has a child, or is invalid */
  fun bad_valsize(): I32 => -30781  /** Unsupported size of key/DB name/data, or wrong DUPFIXED size */
  fun bad_dbi(): I32 => -30780	/** DBI was changed unexpectedly */

// Environment statistics
struct MDBstat
  """
  Some interesting statistics about the Environment or Database.
  """
  var psize: USize = 0    // Page size
  var depth: USize = 0    // Deepest B-tree
  var bpages: USize = 0   // Non-leaf page count
  var lpages: USize = 0   // Leaf page count
  var opages: USize = 0   // Overflow page count
  var entries: USize = 0  // Total record count

  new create() => None

// Environment info
struct MDBinfo
  """
  Information specific to the Environment
  """
  var mapaddr: Pointer[U8] = Pointer[U8].create() // Address of map, if fixed
  var mapsize: USize = 0     // Size of mapped area
  var last_pgno: USize = 0   // ID of last used page
  var last_txid: USize = 0   // ID of last commited transaction
  var maxreaders: USize = 0  // Max reader slots
  var numreaders: USize = 0  // Number of used slots

class MDBVersion
  """
  LMDB software version number.
  """
  var major: USize = 0
  var minor: USize = 0
  var patch: USize = 0
  new create() =>
    @mdb_version( addressof major, addressof minor, addressof patch )

class MDBEnvironment
  """
  The LMDB Environment consists of a single (large) region of virtual memory
  that is mapped to a file.   All LMDB operations take place within
  this Environment.
  """
  var _mdbenv: Pointer[MDBenv] = Pointer[MDBenv].create()
  let _notifier: (MDBNotify | None)

  new create( note: (MDBNotify | None) = None ) ? =>
    """
    Create a new MDBEnvironment context.  This does not open any files
    yet;  that happens in open().
    """
    // The Notifier is optional.
    _notifier = note
    let err = @mdb_env_create( addressof _mdbenv )
    report_error( err )?

  fun ref open( path: String, flags: FlagMask, mode: USize ) ? =>
    """
    Open the environment, associating it with a backing file.  This
    will contain one or more "databases".
    """
    let err = @mdb_env_open( _mdbenv,
	path.cstring(),
	flags or MDBenvflag.notls(),  // Force not using Thread Local Storage
	mode )
    report_error( err )?

  fun ref copy( path: String, flags: FlagMask = 0 ) ? =>
    """
    Make a copy of the entire environment.  This can be used to
    create backups.
    """
    let err = if flags == 0 then
      @mdb_env_copy( _mdbenv, path.cstring() )
    else
      @mdb_env_copy2( _mdbenv, path.cstring(), flags )
    end
    report_error( err )?

  fun ref info(): MDBinfo =>
    """
    Get interesting information about the Environment.
    """
    var infop: MDBinfo = MDBinfo.create()
    @mdb_env_info( _mdbenv, addressof infop )
    infop

  fun ref stats(): MDBstat =>
    """
    Return statistics about the environment
    """
    var statp: MDBstat = MDBstat.create()
    @mdb_env_stat( _mdbenv, statp )
    statp

  fun ref flush( force: Bool = false ) ? =>
    """
    Insure that the underlying file is up to date.
    """
    report_error( @mdb_env_sync( _mdbenv, if force then 1 else 0 end ))?

  fun ref close() =>
    @mdb_env_close( _mdbenv )

  fun ref set_flags( flags: FlagMask, set: Bool ) =>
    """
    Set or clear environment flags after it has been created.
    """
    if set then
      @mdb_env_set_flags( _mdbenv, flags, 1 )
    else
      @mdb_env_set_flags( _mdbenv, flags, 0 )
    end

  fun ref get_flags(): FlagMask ? =>
    """
    Get current Environment flags
    """
    var flags: FlagMask = 0
    report_error( @mdb_env_get_flags( _mdbenv, addressof flags ))?
    flags

  fun ref get_path(): String ? =>
    """
    Get the file system path where the environment is stored.
    """
    var sptr: Pointer[U8] val = recover val Pointer[U8].create() end
    report_error( @mdb_env_get_path( _mdbenv, addressof sptr ))?
    // We have to copy the string because it is in the mapped area.
    recover val String.copy_cstring( sptr ) end

  fun ref set_mapsize( size: USize ) ? =>
    """
    Set the size of the memory map to use for this environment.
    The size should be a multiple of the OS page size. The default is
    10,485,760 bytes (2560 pages). The size of the memory map is also
    the maximum size of the database. The value should be chosen as
    large as possible, to accommodate future growth of the database.
    This function should be called after create and before open.
    """
    report_error( @mdb_env_set_mapsize( _mdbenv, size ))?

  fun ref set_maxslots( count: USize ) ? =>
    """
    Set the maximum number of threads/reader slots for the environment.
    This defines the number of slots in the lock table that is used to
    track readers in the the environment. The default is 126.
    Starting a read-only transaction normally ties a lock table slot to the
    current thread until the environment closes or the thread exits. If
    NOTLS is in use, env.begin() instead ties the slot to the
    MDBtxn object until it or the MDBenv object is destroyed.
    This function may only be called after create() and before open().
    """
    report_error( @mdb_env_set_maxreaders( _mdbenv, count ))?

  fun ref slots() ? =>
    """
    Get the maximum number of threads/reader slots for the environment.
    """
    var count: USize = 0
    report_error( @mdb_env_get_maxreaders( _mdbenv, addressof count ))?
    count

  fun ref set_maxdb( count: USize ) ? =>
    """
    Set the maximum number of named databases for the environment.
    This function is only needed if multiple databases will be used in the
    environment. Simpler applications that use the environment as a single
    unnamed database can ignore this option.
    This function may only be called after create and before open.
    Currently a moderate number of slots are cheap but a huge number gets
    expensive: 7-120 words per transaction, and every DB open does a
    linear search of the opened slots.
    """
    report_error( @mdb_env_set_maxdbs( _mdbenv, count ))?

  fun ref maxkeysize(): USize =>
    """
    Get the maximum size of keys and DUPSORT data we can write.
    This depends on the compile-time constant #MDB_MAXKEYSIZE. Default 511.
    """
    @mdb_env_get_maxkeysize( _mdbenv )

  fun ref set_appinfo( infop: Pointer[Any] ) ? =>
    """
    Set application information associated with the Environment.
    """
    report_error( @mdb_env_set_userctx( _mdbenv, infop ))?

  fun ref get_appinfo(): Pointer[Any] =>
    """
    Get the application information associated with the #MDBenv.
    """
    @mdb_env_get_userctx( _mdbenv )

  fun ref begin( flags: FlagMask = 0,
    parent: (MDBTransaction | None) = None ): MDBTransaction ? =>
    """
    Start a transaction within this environment.
    """
    Debug.out("Env begin flags=" + flags.string())
    var txnhdl: Pointer[MDBtxn] = Pointer[MDBtxn].create()
    let err = match parent
      | None =>
	    @mdb_txn_begin( _mdbenv,
		Pointer[MDBtxn].create(), // Null pointer for no parent
		flags, addressof txnhdl )
      | let p: MDBTransaction =>
	    @mdb_txn_begin( _mdbenv,
		p.handle(),
		flags, addressof txnhdl )
      end
    report_error( err )?

    MDBTransaction.create( this, txnhdl )

  fun ref report_error( code: Stat ) ? =>
    """
    If the user has supplied a notifier class, convert errors to strings
    and send them there.
    """
    // Zero is no error at all.
    if code == 0 then return end
    // If a Notify class was provided, give it a chance
    match _notifier
      | None => None
      | let n: MDBNotify =>
	  let msg = recover val String.from_cstring( @mdb_strerror( code ) ) end
	  n.fail( this, code, consume msg )
    end
    // Now error
    error

  fun ref getenv(): Pointer[MDBenv] =>
    _mdbenv
