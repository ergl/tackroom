primitive SqliteOpen
 fun readonly(): U32 => 0x00000001  /* Ok for sqlite3_open_v2() */
 fun readwrite(): U32 =>        0x00000002  /* Ok for sqlite3_open_v2() */
 fun createdb(): U32 =>           0x00000004  /* Ok for sqlite3_open_v2() */
 fun deleteonclose(): U32 =>    0x00000008  /* VFS only */
 fun exclusive(): U32 =>        0x00000010  /* VFS only */
 fun autoproxy(): U32 =>        0x00000020  /* VFS only */
 fun uri(): U32 =>              0x00000040  /* Ok for sqlite3_open_v2() */
 fun memory(): U32 =>           0x00000080  /* Ok for sqlite3_open_v2() */
 fun main_db(): U32 =>          0x00000100  /* VFS only */
 fun temp_db(): U32 =>          0x00000200  /* VFS only */
 fun transient_db(): U32 =>     0x00000400  /* VFS only */
 fun main_journal(): U32 =>     0x00000800  /* VFS only */
 fun temp_journal(): U32 =>     0x00001000  /* VFS only */
 fun subjournal(): U32 =>       0x00002000  /* VFS only */
 fun master_journal(): U32 =>   0x00004000  /* VFS only */
 fun nomutex(): U32 =>          0x00008000  /* Ok for sqlite3_open_v2() */
 fun fullmutex(): U32 =>        0x00010000  /* Ok for sqlite3_open_v2() */
 fun sharedcache(): U32 =>      0x00020000  /* Ok for sqlite3_open_v2() */
 fun privatecache(): U32 =>     0x00040000  /* Ok for sqlite3_open_v2() */
 fun wal(): U32 =>              0x00080000  /* VFS only */

primitive SqliteError
  fun ok(): U32 => 0   /* Successful result */
  fun err(): U32 => 1   /* SQL error or missing database */
  fun internal(): U32 => 2   /* Internal logic error in SQLite */
  fun perm(): U32 => 3   /* Access permission denied */
  fun abort(): U32 => 4   /* Callback routine requested an abort */
  fun busy(): U32 => 5   /* The database file is locked */
  fun locked(): U32 => 6   /* A table in the database is locked */
  fun nomem(): U32 => 7   /* A malloc() failed */
  fun readonly(): U32 => 8   /* Attempt to write a readonly database */
  fun interrupt(): U32 => 9   /* Operation terminated by sqlite3_interrupt()*/
  fun ioerr(): U32 => 10   /* Some kind of disk I/O error occurred */
  fun corrupt(): U32 => 11   /* The database disk image is malformed */
  fun notfound(): U32 => 12   /* Unknown opcode in sqlite3_file_control() */
  fun full(): U32 => 13   /* Insertion failed because database is full */
  fun cantopen(): U32 => 14   /* Unable to open the database file */
  fun protocol(): U32 => 15   /* Database lock protocol error */
  fun empty(): U32 =>  16   /* Database is empty */
  fun schema(): U32 => 17   /* The database schema changed */
  fun toobig(): U32 => 18   /* String or BLOB exceeds size limit */
  fun constraint(): U32 => 19   /* Abort due to constraint violation */
  fun mismatch(): U32 => 20   /* Data type mismatch */
  fun misuse(): U32 => 21   /* Library used incorrectly */
  fun nolfs(): U32 =>  22   /* Uses OS features not supported on host */
  fun auth(): U32 =>   23   /* Authorization denied */
  fun format(): U32 => 24   /* Auxiliary database format error */
  fun range(): U32 =>  25   /* 2nd parameter to sqlite3_bind out of range */
  fun notadb(): U32 => 26   /* File opened that is not a database file */
  fun notice(): U32 => 27   /* Notifications from sqlite3_log() */
  fun warning(): U32 => 28   /* Warnings from sqlite3_log() */
  fun row(): U32 =>    100  /* sqlite3_step() has another row ready */
  fun done(): U32 =>   101  /* sqlite3_step() has finished executing */

  fun msg( code: U32 ): String =>
    if code==100 then
      "next() has another row ready"
    elseif code==101 then
      "next or execute() has finished executing"
    else
      try [
	    "Successful result",
	    "SQL error or missing database",
	    "Internal logic error in SQLite",
	    "Access permission denied",
	    "Callback routine requested an abort",
	    "The database file is locked",
	    "A table in the database is locked",
	    "A malloc() failed",
	    "Attempt to write a readonly database",
	    "Operation terminated by sqlite3_interrupt()",
	    "Some kind of disk I/O error occurred",
	    "The database disk image is malformed",
	    "Unknown opcode in sqlite3_file_control()",
	    "Insertion failed because database is full",
	    "Unable to open the database file",
	    "Database lock protocol error",
	    "Database is empty",
	    "The database schema changed",
	    "String or BLOB exceeds size limit",
	    "Abort due to constraint violation",
	    "Data type mismatch",
	    "Library used incorrectly",
	    "Uses OS features not supported on host",
	    "Authorization denied",
	    "Auxiliary database format error",
	    "2nd parameter to sqlite3_bind out of range",
	    "File opened that is not a database file",
	    "Notifications from sqlite3_log()",
	    "Warnings from sqlite3_log()"](code.usize())
         else
	    "Unknown error"
         end
        end
