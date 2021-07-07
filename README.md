# 《x86汇编语言：从实模式到保护模式》 Notes
---
## Tools
### Editor
[VSCode](https://code.visualstudio.com/) with extensions: [x86 and x86_64 Assembly](https://marketplace.visualstudio.com/items?itemName=13xforever.language-x86-64-assembly), [Hex Editor](https://marketplace.visualstudio.com/items?itemName=ms-vscode.hexeditor)
### Compiler
[NASM](https://nasm.us/)
### Debugger 
[Bochs](https://bochs.sourceforge.io/)

### Other related tools refer to [author's homepage](http://www.lizhongc.com/index.php/91.html)

---
## Problems in setting up
1. Checkpoint 4.1 has errors in code, refer to [this repo](https://github.com/zzmdy520/x86-assembly).

2. Refer to booktool/相关教程 for creation of virtual disk

3. Bochs will create a .lock file in the same folder of virtual disk when it visits the disk to [avoid opening twice](https://sourceforge.net/p/bochs/discussion/39592/thread/31fc794e/).
When using the 'q' to quit the bochsdbg, this file won't be deleted automatically and the next visit will be forbidden. 
Delete the .lock file mannually or **use 'exit' to quit the debugger** can help. (解决bochsdbg无法打开vhd的问题)
