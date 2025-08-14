import 'package:flutter/material.dart';

// 👇 TOKEN ACTIVATION SCREEN
class TokenActivatePage extends StatefulWidget {
  const TokenActivatePage({super.key});

  @override
  State<TokenActivatePage> createState() => _TokenActivatePageState();
}

// 👇 TOKEN ACTIVATION SCREEN FUNCTIONS HANDLING
class _TokenActivatePageState extends State<TokenActivatePage> {
  final TextEditingController tokenController =
      TextEditingController(); // 👈 controller for token text field
  bool activating = false; // 👈 tracks activation/deactivation loading state
  bool isActive =
      false; // 👈 tracks current token state (false = needs activation, true = active)

  @override
  void dispose() {
    tokenController.dispose(); // 👈 clean up controller
    super.dispose();
  }

  Future<void> _toggleActivation() async {
    setState(() => activating = true); // 👈 start loading
    await Future.delayed(
      Duration(milliseconds: isActive ? 800 : 1000),
    ); // 👈 simulate request time (activate slightly longer)
    setState(() {
      isActive =
          !isActive; // 👈 flip state: Activate → Deactivate or vice versa
      activating = false; // 👈 stop loading
    });

    // 👇 show feedback toast
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isActive
              ? 'Activated token: ${tokenController.text.trim().isEmpty ? 'EMPTY' : tokenController.text.trim()}' // 👈 activation message
              : 'Token deactivated',
        ), // 👈 deactivation message
      ),
    );
  }

  // 👇 TOKEN ACTIVATION SCREEN INTERFACE
  @override
  Widget build(BuildContext context) {
    // 👇 colors swap based on state (as requested: press to change color/label and vice versa)
    final bool showActivate =
        !isActive; // 👈 when true, button says Activate (green)
    final Color buttonBg = showActivate
        ? Colors
              .lightGreenAccent
              .shade100 // 👈 light green for Activate
        : Colors.redAccent.shade100; // 👈 light red for Deactivate

    // 👇 MediaQuery-based responsiveness (already present)
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    return Scaffold(
      backgroundColor: Colors.black, // 👈 tactical dark background
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(
          255,
          21,
          21,
          21,
        ), // 👈 subtle dark app bar
        foregroundColor: Colors.white,
        title: const Text('Unit Key Activation'), // 👈 page title
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // 👈 allows content to stay near the top but scroll if needed
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            24,
          ), // 👈 keep content "near below the app bar"
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isLandscape ? screenWidth * 0.5 : 520,
              ), // 👈 keeps UI narrow and sleek on large screens
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 👇 Card-like panel for the field (sleek tactical look)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                        255,
                        18,
                        18,
                        18,
                      ), // 👈 near-black panel
                      borderRadius: BorderRadius.circular(
                        16,
                      ), // 👈 soft, modern corners
                      border: Border.all(
                        color: Colors.blueGrey.shade700,
                        width: 1,
                      ), // 👈 subtle outline
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromARGB(
                            120,
                            0,
                            0,
                            0,
                          ), // 👈 soft shadow for depth
                          blurRadius: 12,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: tokenController,
                      style: const TextStyle(
                        color: Colors.white,
                      ), // 👈 white text for dark theme
                      cursorColor: Colors
                          .cyanAccent, // 👈 bright cursor matches focus border
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) =>
                          _toggleActivation(), // 👈 pressing Enter toggles activation
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.vpn_key,
                          color: Colors.white70,
                        ), // 👈 key icon inside field
                        filled: true,
                        fillColor: const Color.fromARGB(
                          255,
                          28,
                          28,
                          28,
                        ), // 👈 dark tactical field background
                        hintText: 'Enter Key Here', // 👈 required hint text
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                        ), // 👈 subtle hint color
                        contentPadding: EdgeInsets.symmetric(
                          vertical: isLandscape ? 14 : 18,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.0),
                          borderSide: const BorderSide(
                            color: Colors.transparent,
                            width: 0,
                          ), // 👈 remove harsh default border
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.0),
                          borderSide: BorderSide(
                            color: Colors.blueGrey.shade600,
                            width: 1.2,
                          ), // 👈 calm steel border
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14.0)),
                          borderSide: BorderSide(
                            color: Colors.cyanAccent,
                            width: 2,
                          ), // 👈 neon-like focus ring
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ), // 👈 place button directly under field (near the app bar)
                  // 👇 Single toggle button (Activate ↔ Deactivate) with color change
                  SizedBox(
                    height: 52, // 👈 consistent tall button
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            buttonBg, // 👈 dynamic background color
                        foregroundColor: Colors.black, // 👈 high-contrast text
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        elevation: showActivate
                            ? 3
                            : 0, // 👈 slight elevation when in Activate state
                      ),
                      onPressed: activating
                          ? null
                          : _toggleActivation, // 👈 disable during loading
                      child: activating
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                          : Text(
                              showActivate ? 'ACTIVATE' : 'DEACTIVATE',
                            ), // 👈 swap label based on state
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
