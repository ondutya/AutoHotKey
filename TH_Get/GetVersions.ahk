#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
;F11::suspend  ;挂起所有热键，但对进行中的无影响
;#p::Pause  ;暂停脚本的当前线程，再按一次则取消暂停
;#q::ExitApp  ;退出脚本
;^!q::Reload  ; 设定 Ctrl+Alt+q 热键来重启脚本.
;#g::
rarPath = 
ServerPath = 
LocalPath = 
FileType = 
Start = FALSE
IfExist,C:\PathAll.txt
{
	FileReadLine,rarPath,C:\PathAll.txt,1
	Loop, Read,C:\PathAll.txt
	{
		Start = FALSE
		Loop, parse, A_LoopReadLine,!,
		{
			if a_index = 2
			{
				ServerPath = %A_LoopField%
			}
			if a_index = 3
			{
				LocalPath = %A_LoopField%
			}
			if a_index = 4
			{
				FileType = %A_LoopField%
				Start = 1
				if FileType contains rar
					Start = 4.0
			}
			;MsgBox, 内部循环%A_Index% is %A_LoopField%，Start=%Start%
		}
		;MsgBox, 外循环 类型%Start%！%A_Index%！%ServerPath%！%LocalPath%！%FileType%！
		if Start=1
		{
			;MsgBox,类型%Start%，%rarPath%！%ServerPath%！%LocalPath%！%FileType%！
			Gosub GetVersions
		}
		else if Start=4.0
		{
			;MsgBox,类型%Start%，%rarPath%！%ServerPath%！%LocalPath%！%FileType%！
			IfExist,%ServerPath%\%FileType%
			{
				MsgBox,4,,4.0版本的文件 %ServerPath%\%FileType%`n`nYes跳过(默认)`n`nNo! 重更新一遍,3
				IfMsgBox No
				{
					RunWait,%rarPath% X -o+  %ServerPath%\%FileType% %LocalPath%
				}
			}
			IfInString,ServerPath,V4.0.3
				ServerPath = %ServerPath%\发布版
			IfExist,%ServerPath%\更新\
			{
				MsgBox,4,,Yes(默认)：只获取今日更新`nNo! 获取全部更新,3
				IfMsgBox Yes
				{
					;只更新文件夹
					Loop,%ServerPath%\更新\*,2,0
						FileCopyDir, %ServerPath%\更新\%A_LoopFileName%, %LocalPath%\release\bin\%A_LoopFileName%,1
					Loop,%ServerPath%\更新\*.*
					{
						Time4 = %A_YYYY%%A_MM%%A_DD%
						IfInString,A_LoopFileTimeModified,%Time4%
						{
							FileCopy, %ServerPath%\更新\%A_LoopFileName%, %LocalPath%\release\bin,1
							;MsgBox,创建时间%A_LoopFileTimeModified%，日期%A_YYYY%%A_MM%%A_DD%
							;%LocalPath%\release\bin,1
						}
					}
				}
				else
				{
					FileCopyDir, %ServerPath%\更新\, %LocalPath%\release\bin,1
				}
				MsgBox,64,,4.0 的补丁拷贝完毕！不信你自己拷贝去~,2
			}
		}
	}
	if ErrorLevel
	{
		MsgBox,指定的行号大于文件的行数
		return
	}
}
else
{
	MsgBox,设置好路径文件再运行好嘛~
	return
}
return

GetVersions:
TimeNow = %A_YYYY%%A_MM%
FileList =  
FileName =  
FileNameNow =  
Loop,%ServerPath%\%TimeNow%*.*,1,0
	FileList = %FileList%%A_LoopFileName%`n
Sort, FileList,R
;MsgBox,%FileList%
Loop, parse, FileList, `n
{
    if A_LoopField =  ;忽略列表末尾的空项.
		continue
	FileName = %A_LoopField%
	IfExist,%ServerPath%\%FileName%\%FileName%.%FileType%.rar
		break
}
;MsgBox,%FileName%.%FileType%.rar
SetWorkingDir,%ServerPath%\%FileName%\
FileGetTime,OutputVar,%FileName%.%FileType%.rar, C ;获取创建时间
IfExist,%LocalPath%\UpdateHistory
{
	IfExist,%LocalPath%\UpdateHistory\更新历史.txt
	{
		Loop, read, %LocalPath%\UpdateHistory\更新历史.txt
			last_line := A_LoopReadLine ;当循环结束时, 这里会保持最后一行的内容.
	}
	else
	{
		FileAppend,2014`n,%LocalPath%\UpdateHistory\更新历史.txt ;写入
		last_line = 2014
	}
}
else
{
	FileCreateDir, %LocalPath%\UpdateHistory
	FileAppend,2014`n,%LocalPath%\UpdateHistory\更新历史.txt ;写入
}
IfNotInString,last_line, 201
{
	MsgBox,本月无新版本啊！
	return
}
;MsgBox,rarPath=%rarPath%`n`nPath=%Path%`n`nfileType=%fileType%
;比较记录的时间和服务器文件的时间
if ( last_line = OutputVar )
{
	FileNameNow=%FileName%
	msgbox,4,,%FileName%：为最新可用文件，本地文件与服务器一致耶！ `n`nYes(默认)：将拷贝“更新”文件(如果有的话:D)...`n`nNo! 我好闲，让我们再更新一次吧！,3
	IfMsgBox No
	{
		MsgBox,64,,你确实很闲~,3
		Gosub GetBridgeDesigner
		Gosub GetGX
	}
	else
	{
		Gosub GetGX
	}
}
else
{
	MsgBox,3,,服务器有新版本%FileName%，本地版本是%last_line%`n`nYes(默认)，获取服务器的新版本`nNo! 获取本地旧版本的更新`n`取消！什么也不做,3
	IfMsgBox Yes
	{
		FileNameNow=%FileName%
		Gosub GetBridgeDesigner
		Gosub GetGX
	}
	IfMsgBox No
	{
		FileNameNow=%last_line%
		Gosub GetGX
	}
	IfMsgBox Cancel
		return
	IfMsgBox Timeout
	{
		FileNameNow=%FileName%
		Gosub GetBridgeDesigner
		Gosub GetGX
	}
}
Return

;获取并解压方案设计师
GetBridgeDesigner:
IfExist,%ServerPath%\%FileNameNow%\%FileNameNow%.%FileType%.rar
{
	;MsgBox,%FileNameNow%.%FileType%.rar
	RunWait,%rarPath% X -o+  %FileNameNow%.%FileType%.rar %LocalPath%
	FileAppend,%OutputVar%`n,%LocalPath%\UpdateHistory\更新历史.txt  ;写入
	SoundPlay, %A_WinDir%\Media\ding.wav
}
return
;获取方案设计师更新
GetGX:
IfExist,%ServerPath%\%FileNameNow%\更新
{
	;FileListGX =
	;Loop,%ServerPath%\%FileNameNow%\更新\*.*
		;FileListGX = %FileListGX%%A_LoopFileName%`n
	;MsgBox,%FileListGX%
	;FileCopy,%ServerPath%\%FileName%\更新\*.dll, %LocalPath%\release\bin,1
	FileCopyDir, %ServerPath%\%FileName%\更新, %LocalPath%\release\bin,1
	MsgBox,64,,服务器路径%ServerPath%`n`n补丁更新完毕，不信你去看看~,2
}
else
	MsgBox,48,,服务器路径%ServerPath%`n`n竟然没有补丁，不过我相信这只是暂时的！,2
return
