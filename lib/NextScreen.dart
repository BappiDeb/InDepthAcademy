import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_depth_academy/LoginScreen.dart';
import 'package:flutter/services.dart';
import 'package:no_screenshot/no_screenshot.dart';

class NextScreen extends StatefulWidget {
  @override
  _NextScreenState createState() => _NextScreenState();
}

class _NextScreenState extends State<NextScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final noScreenshot = NoScreenshot.instance;
  late AnimationController _animationController;
  late Animation<Offset> _animation;
  String _userEmail = '';
  double _progress = 0;
  bool _isLoading = true;
  static const platform = MethodChannel('io.alexmelnyk.utils');
  InAppWebViewController? _webViewController;

  get minutes => null;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    WidgetsBinding.instance.addObserver(this);
    noScreenshot.screenshotOff();
    _loadUserEmail();
    _setScreenCaptureProtection(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _setScreenCaptureProtection(false);
    super.dispose();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _animation = Tween<Offset>(
      begin: Offset(-0.3, -0.3),
      end: Offset(1.3, 1.3),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('userEmail') ?? 'No Email Found';
    });
  }

  Future<void> _setScreenCaptureProtection(bool enable) async {
    try {
      await platform.invokeMethod('preventScreenCapture', {'enable': enable});
    } on PlatformException catch (e) {
      print("Failed to set screen capture protection: '${e.message}'.");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _setScreenCaptureProtection(false);
    } else if (state == AppLifecycleState.resumed) {
      _setScreenCaptureProtection(true);
      noScreenshot.screenshotOff();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              if (_isLoading) LinearProgressIndicator(value: _progress),
              Expanded(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri(
                        'https://www.in-depth-academy.com/student-yarapatmaged'),
                  ),
                  initialOptions: InAppWebViewGroupOptions(
                    crossPlatform: InAppWebViewOptions(
                        // Removed mediaPlaybackRequiresUserAction as it might not be available
                        ),
                    ios: IOSInAppWebViewOptions(
                      allowsInlineMediaPlayback: true,
                      allowsAirPlayForMediaPlayback: false,
                    ),
                  ),
                  onWebViewCreated: (controller) {
                    // Initialize WebView controller if needed
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      _isLoading = true; // Show the progress indicator
                    });
                  },
                  onLoadStop: (controller, url) async {
                    setState(() {
                      _isLoading = false; // Hide the progress indicator
                      _progress = 1.0; // Set progress to 100%
                    });
                    // Inject custom controls when the page loads

                    await controller.evaluateJavascript(source: """
(function() {
  function injectCustomControls() {
    var videos = document.querySelectorAll('video');

    videos.forEach(function(video) {
      // Ensure videos play inline on iOS
      video.setAttribute('playsinline', '');

      // Disable native controls
      video.controls = false;

      // Check if custom controls have already been injected
      if (video.getAttribute('data-custom-controls-injected') === 'true') return;

      // Create custom controls container
      var customControls = document.createElement('div');
      customControls.id = 'custom-controls';
      customControls.style.position = 'absolute';
      customControls.style.bottom = '0px';
      customControls.style.left = '0px';
      customControls.style.width = '100%';
      customControls.style.zIndex = '10000';
      customControls.style.backgroundColor = 'rgba(0, 0, 0, 0.7)';
      customControls.style.padding = '10px';
      customControls.style.borderRadius = '5px';
      customControls.style.display = 'flex';
      customControls.style.alignItems = 'center';
      customControls.style.boxSizing = 'border-box';

      // Create play/pause button container
      var centerControls = document.createElement('div');
      centerControls.style.position = 'absolute';
      centerControls.style.top = '50%';
      centerControls.style.left = '50%';
      centerControls.style.transform = 'translate(-50%, -50%)';
      centerControls.style.zIndex = '10001'; // Ensure it is above the video
      centerControls.style.display = 'flex';
      centerControls.style.alignItems = 'center';
      centerControls.style.justifyContent = 'center';

      // Create Play and Pause buttons
      var playButton = document.createElement('button');
      playButton.id = 'play-button';
      playButton.innerHTML = '&#9658;'; // Play icon
      playButton.style.fontSize = '48px'; // Adjust size for visibility
      playButton.style.color = 'white';
      playButton.style.backgroundColor = 'transparent';
      playButton.style.border = 'none';
      playButton.style.outline = 'none';
      playButton.style.cursor = 'pointer';

      var pauseButton = document.createElement('button');
      pauseButton.id = 'pause-button';
      pauseButton.innerHTML = '&#10074;&#10074;'; // Pause icon
      pauseButton.style.fontSize = '48px'; // Same size as play button
      pauseButton.style.color = 'white';
      pauseButton.style.backgroundColor = 'transparent';
      pauseButton.style.border = 'none';
      pauseButton.style.outline = 'none';
      pauseButton.style.cursor = 'pointer';
      pauseButton.style.display = 'none'; // Initially hidden

      // Append buttons to the center controls container
      centerControls.appendChild(playButton);
      centerControls.appendChild(pauseButton);

      // Append center controls and other controls to the video container
      video.parentElement.style.position = 'relative'; // Ensure the parent is positioned
      video.parentElement.appendChild(centerControls);
      video.parentElement.appendChild(customControls);

      // Custom control functions
      var seekBar = document.createElement('input');
      seekBar.type = 'range';
      seekBar.id = 'seek-bar';
      seekBar.value = '0';
      seekBar.style.flexGrow = '1';
      seekBar.style.margin = '0 10px';
      customControls.appendChild(seekBar);

      var currentTime = document.createElement('span');
      currentTime.id = 'current-time';
      currentTime.style.color = 'white';
      currentTime.textContent = '0:00';
      customControls.appendChild(currentTime);

      playButton.addEventListener('click', function() {
        video.play();
        playButton.style.display = 'none';
        pauseButton.style.display = 'block';
        customControls.style.display = 'flex'; // Show the seek bar
        resetHideControlsTimer(); // Reset timer on interaction
      });

      pauseButton.addEventListener('click', function() {
        video.pause();
        playButton.style.display = 'block';
        pauseButton.style.display = 'none';
        customControls.style.display = 'flex'; // Show the seek bar
        resetHideControlsTimer(); // Reset timer on interaction
      });

      video.addEventListener('timeupdate', function() {
        var duration = video.duration || 0;
        var currentTimeValue = video.currentTime || 0;
        var value = (currentTimeValue / duration) * 100;
        seekBar.value = value;

        var minutes = Math.floor(currentTimeValue / 60);
        var seconds = Math.floor(currentTimeValue % 60);
        currentTime.textContent = minutes + ':' + (seconds < 10 ? '0' + seconds : seconds);
      });

      seekBar.addEventListener('input', function() {
        var value = seekBar.value * video.duration / 100;
        video.currentTime = value;
        resetHideControlsTimer(); // Reset timer on interaction
      });

      // Set flag to prevent duplicate control injection
      video.setAttribute('data-custom-controls-injected', 'true');

      // Show controls when paused
      video.addEventListener('pause', function() {
        centerControls.style.display = 'flex';
        customControls.style.display = 'flex'; // Show the seek bar
        resetHideControlsTimer(); // Reset timer on interaction
      });

      // Show controls on play
      video.addEventListener('play', function() {
        centerControls.style.display = 'flex';
        customControls.style.display = 'flex'; // Show the seek bar
        resetHideControlsTimer(); // Reset timer on interaction
      });

      // Show controls on video click
      video.addEventListener('click', function() {
        centerControls.style.display = 'flex';
        customControls.style.display = 'flex'; // Show the seek bar
        resetHideControlsTimer();
      });

      // Hide controls after inactivity
      var hideControlsTimer;
      function resetHideControlsTimer() {
        clearTimeout(hideControlsTimer);
        hideControlsTimer = setTimeout(function() {
          centerControls.style.display = 'none';
          customControls.style.display = 'none';
        }, 1500); // Hide after 1.5 seconds of inactivity
      }

      // Reset timer when interacting with controls or touching/moving the document
      customControls.addEventListener('click', function() {
        resetHideControlsTimer();
      });
      document.addEventListener('touchstart', resetHideControlsTimer);
    });
  }

  // Inject custom controls on page load
  injectCustomControls();

  // Reapply custom controls when new videos are added dynamically
  var observer = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      if (mutation.addedNodes.length) {
        injectCustomControls();
      }
    });
  });

  observer.observe(document.body, { childList: true, subtree: true });
})();




""");
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() {
                      _progress = progress / 100;
                    });
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    print(consoleMessage.message);
                  },
                ),
              ),
            ],
          ),
          _buildAnimatedEmailOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return isLandscape
        ? null
        : AppBar(
            title: Text(_userEmail),
            actions: [
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('isLoggedIn');
                  await prefs.remove('userEmail');
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
              ),
            ],
          );
  }

  Widget _buildAnimatedEmailOverlay() {
    return SlideTransition(
      position: _animation,
      child: AnimatedOpacity(
        opacity: 0.2,
        duration: Duration(milliseconds: 3000),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            _userEmail.isNotEmpty ? _userEmail : 'Loading...',
            style: TextStyle(
              fontSize: 20,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
