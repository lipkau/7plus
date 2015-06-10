;~ -----------------------------------------------------------------------------
;~ Name:               WinSCP Class
;~ -----------------------------------------------------------------------------
;~ Version:            1.0
;~ Date:               2015-06-01
;~ Author:             Lipkau, Oliver <oliver@lipkau.net>
;~                     https://githubom/lipkau
;~                     http://oliver.lipkau.net/blog
;~ -----------------------------------------------------------------------------
;~ TODO:
;~ 		- Try/Catch if dll is not registered?
;~ 		- Split constructer from open connection?
;~ 		- Allow dll to be outside A_ScriptDir?
;~ 		- better documentation
;~ 		- more methods
;~ 		- cleanup

if (!FileExist("WinSCPnet.dll")) {
	MsgBox, 16, Error, Missing WinSCPnet.dll
	Exit
}

;~ if not A_IsAdmin {
   ;~ Run *RunAs "%A_ScriptDir%\WinSCP_regDLL.cmd" ; Requires v1.0.92.01+
;~ } else {
	;~ Run, "%A_ScriptDir%\WinSCP_regDLL.cmd"
;~ }

class FTP ;extends BaseClassName
{
	static FtpMode                 := {Passive: 0, Active:1}
	static FtpSecure               := {None:0, Implicit:1, ExplicitTls:2, ExplicitSsl:3}
	static FtpProtocol             := {Sftp:0, Scp:1, Ftp:2}
	static TransferMode            := {Binary:0, Ascii:1, Automatic:2}
	static SynchronizationMode     := {Local:0, Remote:1, Both:2}
	static SynchronizationCriteria := {None:0, Time:1, Size:2, Either:3}

	static Session := ComObjCreate("WinSCP.Session")
	static SessionOptions := ComObjCreate("WinSCP.SessionOptions")
	static TransferOptions := ComObjCreate("WinSCP.TransferOptions")

	__New(srv,uName, pWord, protocol=2, secure=0, fingerprint=true, port=21, mode="passive")
	{
		;~ Descitipion
		;~ 		Contructor for class - will try opening connection to host
		;~ 
		;~ Input
		;~ 		srv        : [string] Server DNS or IP
		;~ 		uName      : [string] User Name
		;~ 		pWord      : [string] Password
		;~ 		protocol   : [int]    0           : sFTP
		;~ 		                      1           : SCP
		;~							  2 (default) : FTP
		;~ 		secure     : [int]    0 (default) : None
		;~ 							  1           : Implicit
		;~ 							  2           : Explicit TLS
		;~ 							  3           : Explicit SSL
		;~ 		fingerprint: [string] Can be:
		;~ 		                        Fingerprint of SSH server host key.
		;~ 		                        It makes WinSCP automatically accept
		;~ 		                        host key with the fingerprint.
		;~ 		                        Mandatory for SFTP/SCP protocol.
		;~ 		
		;~ 		                        Fingerprint of FTPS server TLS/SSL
		;~ 		                        certificate to be automatically accepted
		;~ 		                        (useful for certificates signed by
		;~ 		                        untrusted authority).
		;~ 		port       : [int]    Port to connect to
		;~ 		mode       : [enum]   Active|Passive Mode
		;~ 
		;~ Output
		;~ 		false : Connection failed
		
		
		;~ FTP Basic
		this.SessionOptions.HostName := srv
		this.SessionOptions.UserName := uName
		this.SessionOptions.Password := pWord
		if (port)
			this.SessionOptions.PortNumber := port
		
		;~ FTP Mode
		this.SessionOptions.FtpMode := this.FtpMode.Passive
		if (mode=="active")
			this.SessionOptions.FtpMode := this.FtpMode.Active
		
		;~ FTP Protocol
		if (protocol==0)
			this.SessionOptions.Protocol := this.FtpProtocol.Sftp
		if else (protocol==1)
			this.SessionOptions.Protocol := this.FtpProtocol.Scp
		if else (protocol==2)
			this.SessionOptions.Protocol := this.FtpProtocol.Ftp
		
		;~ FTP Security
		if (secure==0)
			this.SessionOptions.FtpSecure := this.FtpSecure.None
		else if (secure==1)
			this.SessionOptions.FtpSecure := this.FtpSecure.Implicit
		else if (secure==2)
			this.SessionOptions.FtpSecure := this.FtpSecure.ExplicitTls
		else if (secure==3)
			this.SessionOptions.FtpSecure := this.FtpSecure.ExplicitSsl
		
		;~ Fingerprint
		if (fingerprint)
		{
			if (StrLen(fingerprint) > 1)
			{
				if (secure==3)
					this.SessionOptions.TlsHostCertificateFingerprint := fingerprint
				if (secure==4)
					this.SessionOptions.SshHostKeyFingerprint := fingerprint
			}
		} else {
			if (secure==3)
				this.SessionOptions.GiveUpSecurityAndAcceptAnyTlsHostCertificate := true
			else if (secure==4)
				this.SessionOptions.GiveUpSecurityAndAcceptAnySshHostKey := true
		}
		
		try
			this.OpenConnection()
		catch e
			return false
	}
	
	__Delete()
	{
		this.Session.Dispose()
	}
	
	SetTransferOptions(mode=0)
	{
		;~ Check
		;mode
		if mode not in % this.StringJoin(this.TransferMode,",")
		
		;~ this.TransferOptions.FileMask := 
		;~ this.TransferOptions.FilePermissions := 
		;~ this.TransferOptions.PreserveTimestamp := 
		this.TransferOptions.TransferMode  := TransferMode
		;~ this.TransferOptions.FileMask := 
	}
	
	/*
	Description:
		Opens the session.
		http://winscp.net/eng/docs/library_session_listdirectory
	
	Input:
	Output:
	*/
	OpenConnection()
	{
		this.Session.Open(this.SessionOptions)
	}
	
	/*
	Description:
		Lists the contents of specified remote directory.
		http://winscp.net/eng/docs/library_session_listdirectory
	
	Input:
		[mandatory] [string] Full path to remote directory to be read.
	
	Output:
		[object] RemoteDirectoryInfo
	*/
	ListDirectory(remotePath)
	{
		return this.Session.ListDirectory(remotePath)
	}
	
	/*
	Description:
		Creates remote directory.
		http://winscp.net/eng/docs/library_session_createdirectory
	
	Input:
		[mandatory] [string] Full path to remote directory to create.
	
	Output:
		[void]
	*/  
	CreateDirectory(remotePath)
	{
		return this.Session.CreateDirectory(remotePath)
	}
	
	/*
	Description:
		Checks for existence of remote file.
		http://winscp.net/eng/docs/library_session_fileexists
	
	Input:
		[mandatory] [string] Full path to remote file. Note that you cannot use wildcards here.
	
	Output:
		[bool] true if file exists, false otherwise.
	*/  
	FileExists(remotePath)
	{
		return this.Session.FileExists(remotePath)
	}
	
	/*
	Description:
		Retrieves information about remote file.
		http://winscp.net/eng/docs/library_session_getfileinfo
	
	Input:
		[mandatory] [string] Full path to remote file.
	
	Output:
		[object] RemoteFileInfo
	*/
	GetFileInfo(remotePath)
	{
		return this.Session.GetFileInfo(remotePath)
	}
	
	/*
	Description:
		Downloads one or more files from remote directory to local directory.
		http://winscp.net/eng/docs/library_session_getfiles
	
	Input:
		[mandatory] [string] Full path to remote directory followed by slash and wildcard to
		                     select files or subdirectories to download. When wildcard is
							 omitted (path ends with slash), all files and subdirectories in
							 the remote directory are downloaded.
		[mandatory] [string] Full path to download the file to. When downloading multiple
		                     files, the filename in the path should be replaced with operation
							 mask or omitted (path ends with backslash).
		[optional]  [bool]   When set to true, deletes source remote file(s) after transfer. Defaults to false.
		[optional]  [object] Transfer options. Defaults to null, what is equivalent to new TransferOptions().
		[optional]  [bool]   Converts special characters in file path to make it
		                     unambiguous file mask/wildcard.
	
	Output:
		[object] TransferOperationResult. See also Capturing results of operations.
	*/
	GetFiles(remotePath, localPath, remove=false, options="", escape=false)
	{
		;~ Check
		;remove
		if remove not in 0,1
			throw "Invalid value for remove"
		
		;TransferOptions
		if (options && (ComObjType(options,"Name")=="_TransferOptions"))
			throw "Invalid TransferOptions"
		
		;escape
		if escape not in 0,1
			throw "Invalid value for escape"
		
		if (escape)
			this.remotePath := this.Session.EscapeFileMask(remotePath)
		
		return this.Session.GetFiles(remotePath, localPath, remove, options)
	}
	
	/*
	Description:
		Moves remote file to another remote directory and/or renames remote file.
		http://winscp.net/eng/docs/library_session_movefile
	
	Input:
		[mandatory] [string] Full path to remote file to move/rename.
		[mandatory] [string] Full path to new location/name to move/rename the file to.
	
	Output:
		[void]
	*/
	MoveFile(sourcePath, targetPath)
	{
		return this.Session.MoveFile(sourcePath, targetPath)
	}
	
	/*
	Description:
		Uploads one or more files from local directory to remote directory.
		http://winscp.net/eng/docs/library_session_putfiles
	
	Input:
		[mandatory] [string] Full path to local file or directory to upload. Filename in the
		                     path can be replaced with Windows wildcard1) to select multiple
							 files. When file name is omitted (path ends with backslash), all
							 files and subdirectories in the local directory are uploaded.
		[mandatory] [string] Full path to upload the file to. When uploading multiple files,
		                     the filename in the path should be replaced with operation mask
							 or omitted (path ends with slash).
		[optional]  [bool]   When set to true, deletes source local file(s) after transfer.
		                     Defaults to false.
		[optional]  [object] Transfer options. Defaults to null, what is equivalent to new
		                     TransferOptions().
		[optional]  [bool]   Converts special characters in file path to make it
		                     unambiguous file mask/wildcard.
	
	Output:
		[object] TransferOperationResult. See also Capturing results of operations.
	*/
	;~ PutFiles(localPath, remotePath, remove:=false, options:="", escape:=false)
	PutFiles(localPath, remotePath, escape:=false)
	{
		;~ Checks
		;remove
		;~ if remove not in 0,1
			;~ throw "Invalid value for remove"
		
		;~ ;TransferOptions
		;~ if (options && (ComObjType(options,"Name")=="_TransferOptions"))
			;~ throw "Invalid TransferOptions"
		
		;escape
		if escape not in 0,1
			throw "Invalid value for escape"
		
		if (escape)
			localPath := this.Session.EscapeFileMask(localPath)
		
		remove := false
		
		t := this.Session.PutFiles(localPath, remotePath) ;, , TransferOptions) ;, remove) ;, options)
		return t
	}
	
	/*
	Description:
		Removes one or more remote files.
		http://winscp.net/eng/docs/library_session_removefiles
	
	Input:
		[mandatory] [string] Full path to remote directory followed by slash and
		                     wildcard to select files or subdirectories to remove.
		[optional]  [bool]   Converts special characters in file path to make it
		                     unambiguous file mask/wildcard.
	
	Output:
		[object] RemovalOperationResult. See also Capturing results of operations.
	*/
	RemoveFiles(remotePath, escape=false)
	{
		;~ Checks
		;espace
		if escape not in 0,1
			throw "Invalid value for escape"
		
		if (escape)
			this.remotePath := this.Session.EscapeFileMask(remotePath)
		
		return this.Session.RemoveFiles(remotePath)
	}
	
	/*
	Description:
		Synchronizes directories.
		http://winscp.net/eng/docs/library_session_synchronizedirectories
	
	Input:
		[mandatory] [enum]   Synchronization mode. Possible values are SynchronizationMode.Local, SynchronizationMode.Remote and
		                     SynchronizationMode.Both.
		[mandatory] [string] Full path to local directory.
		[mandatory] [string] Full path to remote directory.
		[mandatory] [bool]   When set to true, deletes obsolete files. Cannot be used for SynchronizationMode.Both.
		[optional]  [bool]   When set to true, synchronizes in mirror mode (synchronizes also older files). Cannot be used for
		                     SynchronizationMode.Both. Defaults to false.
		[optional]  [enum]   Comparison criteria. Possible values are SynchronizationCriteria.None, SynchronizationCriteria.Time
		                     (default), SynchronizationCriteria.Size and SynchronizationCriteria.Either. For
							 SynchronizationMode.Both SynchronizationCriteria.Time can be used only.
		[optional]  [string] Transfer options. Defaults to null, what is equivalent to new TransferOptions().
		
	Output:
		[object] SynchronizationResult. See also Capturing results of operations.
	*/
	SynchronizeDirectories(mode, localPath, remotePath, removeFiles, mirror=false, criteria=1, options="" )
	{
		;~ Checks
		;Mode
		if mode not in % this.StringJoin(this.SynchronizationMode,",")
			throw "Invalid Mode"
		
		;removeFiles
		if removeFiles not in 0,1
			throw "Invalid removeFiles"
		if (removeFiles && (removeFiles==this.SynchronizationMode.Both))
			throw "Deletion of obsolete files cannot be used for SynchronizationMode.Both"
		
		;mirror
		if mirror not in 0,1
			throw "Invalid mirror"
		if (mirror && (removeFiles==this.SynchronizationMode.Both))
			throw "Synchronization in mirror mode (synchronizes also older files) cannot be used for SynchronizationMode.Both"
		
		;TransferOptions
		if (options && (ComObjType(options,"Name")=="_TransferOptions"))
			throw "Invalid TransferOptions"
		
		this.SetTransferOptions(this.TransferMode.Binary)
		options := this.TransferOptions
		
		return this.Session.SynchronizeDirectories(mode, localPath, remotePath, removeFiles, mirror, criteria, options)
	}
	
	
	
	StringJoin(array, delim=";")
	{
		t := ""
		for key, value in array
			t .= (t ? delim : "") . value
		return t
	}
}