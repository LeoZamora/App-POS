import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inversiones_ar/requestHttp/requestHttp.dart';
import 'package:go_router/go_router.dart';
import 'package:inversiones_ar/widgets/ToatsSnackBar.dart';
import 'package:inversiones_ar/widgets/overlayCircle.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:inversiones_ar/features/providers/authProvider.dart';

class LoginApp extends ConsumerStatefulWidget {
  const LoginApp({super.key});

  @override
  ConsumerState<LoginApp> createState() => _LoginAppState();
}

class _LoginAppState extends ConsumerState<LoginApp> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late bool _showPass = true;
  bool _isLoading = false;
  String _nameClient = "Migdalia's Market";

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required Color primaryColor,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),

      prefixIcon: Icon(
        icon,
        size: 21,
        color: Colors.grey.shade500,
      ),

      suffixIcon: suffix,

      filled: true,
      fillColor: const Color(0xFFF8F9FC),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  Future<void> _login() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      LoadingOverlay.show(context, message: 'Iniciando sesión...');
      try {
        Response result = await postLogin({
          'usuario': username,
          'password': password
        });

        LoadingOverlay.hide();

        final String tokenStr = result.data['token'];
        await ref.read(authProvider.notifier).login(tokenStr);

        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      } on DioException catch (e) {
        LoadingOverlay.hide();
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        String mensajeError = 'Ocurrió un error al conectar con el servidor.';

        if (e.response != null) {
          if (e.response!.statusCode == 400) {
            mensajeError = 'Credenciales inválidas. Verifica tu usuario y contraseña.';
          } else {
            mensajeError = 'Error del servidor: ${e.response!.statusCode}';
          }
        }

        ToastSnackBar.show(
          context,
          message: mensajeError,
          type: ToastType.warning,
        );

      } catch (e) {
        LoadingOverlay.hide();
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        ToastSnackBar.show(
          context,
          message: 'Error inesperado. Intente de nuevo.',
          type: ToastType.warning,
        );
      }
    } else {
      // Si el formulario no es válido
      setState(() {
        _isLoading = false;
      });
      ToastSnackBar.show(
        context,
        message: 'Por favor, complete todos los campos.',
        type: ToastType.warning
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4F46E5);
    const darkColor = Color(0xFF111827);
    const backgroundColor = Color(0xFFF7F8FC);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // =========================================================
                    // BRAND
                    // =========================================================

                    Center(
                      child: Column(
                        children: [

                          // Logo
                          Container(
                            width: 82,
                            height: 82,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.10),
                                  blurRadius: 30,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/devo/32px.png',
                              fit: BoxFit.contain,
                            ),
                          ),

                          const SizedBox(height: 24),

                          Text(
                            _nameClient,
                            style: TextStyle(
                              color: darkColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 3,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Soluciones digitales',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 42),

                    // =========================================================
                    // LOGIN CARD
                    // =========================================================

                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.04),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.045),
                            blurRadius: 40,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          // Título
                          const Text(
                            'Bienvenido',
                            style: TextStyle(
                              color: darkColor,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Inicia sesión para continuar',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // =================================================
                          // USUARIO
                          // =================================================

                          Text(
                            'Usuario',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 8),

                          TextFormField(
                            controller: _usernameController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: darkColor,
                            ),
                            decoration: _inputDecoration(
                              hint: 'Ingresa tu usuario',
                              icon: Icons.person_outline_rounded,
                              primaryColor: primaryColor,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu usuario';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // =================================================
                          // CONTRASEÑA
                          // =================================================

                          Text(
                            'Contraseña',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 8),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: _showPass,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: darkColor,
                            ),
                            decoration: _inputDecoration(
                              hint: 'Ingresa tu contraseña',
                              icon: Icons.lock_outline_rounded,
                              primaryColor: primaryColor,
                              suffix: IconButton(
                                splashRadius: 20,
                                onPressed: () {
                                  setState(() {
                                    _showPass = !_showPass;
                                  });
                                },
                                icon: Icon(
                                  _showPass
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu contraseña';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 28),

                          // =================================================
                          // BOTÓN
                          // =================================================

                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Iniciar sesión',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 19,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =========================================================
                    // FOOTER
                    // =========================================================

                    Center(
                      child: Text(
                        '© 2026 DevoDigital · Todos los derechos reservados',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
