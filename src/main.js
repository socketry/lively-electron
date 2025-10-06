const {app, BrowserWindow, ipcMain} = require('electron');
const {spawn, spawnSync} = require('child_process');
const http = require('http');
const net = require('net');
const path = require('path');
const fs = require('fs');

class LivelyElectronApp {
	constructor() {
		this.rubyProcess = null;
		this.mainWindow = null;
		this.serverUrl = null;
		
		// Store the working directory (should be preserved by direct CLI)
		this.originalCwd = process.cwd();
		console.log('💾 Working directory:', this.originalCwd);
	}
	
	isDevelopment() {
		const variant = process.env.LIVELY_VARIANT || process.env.VARIANT;
		return variant === "development";
	}
	
	async start() {
		try {
			// 1. Start Ruby Lively server on TCP localhost
			await this.startLivelyServer();
			
			// 2. Create Electron window (connects directly to Ruby server)
			await this.createWindow();
			
			console.log(`Lively Electron started - Ruby server: ${this.serverUrl}`);
		} catch (error) {
			console.error('Failed to start Lively Electron:', error);
			app.quit();
		}
	}
	
	async startLivelyServer() {
		return new Promise((resolve, reject) => {
			// Forward all CLI args to the Ruby server; let the Ruby script decide the application file
			const args = process.argv.slice(2);
			
			// Create server and let it bind+listen, then pass handle to child
			const server = net.createServer();
			server.listen(0, '127.0.0.1', () => {
				const port = server.address().port;
				this.serverUrl = `http://localhost:${port}`;
				
				const fd = server._handle.fd;
				
				// Start Ruby process with FD passed via stdio and forward all CLI args
				const livelyElectronScript = path.join(__dirname, '..', 'bin', 'lively-electron-server');
				const childArgs = args.slice();
				
				const child = spawn(livelyElectronScript, childArgs, {
					stdio: [
						'inherit',  // stdin
						'inherit',  // stdout
						'inherit',  // stderr
						fd          // Pass socket FD as stdio[3]
					],
					env: { 
						...process.env, 
						LIVELY_SERVER_DESCRIPTOR: '3'  // Tell child it's on FD 3
					}
				});
				
				child.on('spawn', () => {
					this.rubyProcess = child;
					server.close((error) => {
						if (error) {
							reject(error);
						} else {
							console.log(`✅ Ruby server should be ready: ${this.serverUrl}`);
							resolve();
						}
					});
				});
				
				child.on('error', (error) => {
					server.close();
					console.error('Failed to spawn Ruby process:', error);
					reject(error);
				});
				
				child.on('close', (code) => {
					this.rubyProcess = null;
					console.log(`Ruby process exited with code ${code}`);
					if (code !== 0) {
						reject(new Error(`Ruby process failed with code ${code}`));
					}
				});
			});
		});
	}
	
	async createWindow() {
		this.mainWindow = new BrowserWindow({
			width: 1200,
			height: 800,
			webPreferences: {
				nodeIntegration: false,
				contextIsolation: true,
				enableRemoteModule: false
			},
			titleBarStyle: 'hiddenInset'
		});
		
		// Load the Lively app directly
		await this.mainWindow.loadURL(this.serverUrl);
		
		// Open DevTools in development mode
		if (this.isDevelopment()) {
			this.mainWindow.webContents.openDevTools();
		}
		
		this.mainWindow.on('closed', () => {
			this.cleanup();
		});
	}
	
	cleanup() {
		if (this.rubyProcess) {
			this.rubyProcess.kill();
		}
	}
}

// Electron app lifecycle
app.whenReady().then(() => {
	console.log('Electron ready, starting Lively app...');
	const livelyApp = new LivelyElectronApp();
	livelyApp.start().catch(error => {
		console.error('Failed to start Lively app:', error);
		app.quit();
	});
});

app.on('window-all-closed', () => {
	if (process.platform !== 'darwin') {
		app.quit();
	}
});

app.on('activate', () => {
	if (BrowserWindow.getAllWindows().length === 0) {
		const livelyApp = new LivelyElectronApp();
		livelyApp.start();
	}
});

app.on('before-quit', () => {
	// Cleanup will be handled by window close event
});
