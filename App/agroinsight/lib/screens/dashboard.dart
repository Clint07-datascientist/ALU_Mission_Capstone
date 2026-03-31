import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'farm_heatmap.dart';
import 'farm_registration.dart';
import 'history.dart';
import 'sector_overview.dart';
import '../services/ble_ingestion_service.dart';
import '../services/firebase_sync_service.dart';

/// Generate a page named Dashboard
///
/// Dashboard: Top app bar.
///
/// Greeting: "Welcome, Lead Farmer". A status card showing "Hardware Probe
/// Ready". Centerpiece: A massive circular orange button with a camera icon
/// labeled "SCAN LEAF". Below it, an outlined button "VIEW FARM HEATMAP" and
/// a text button "SYNC OFFLINE RECORDS".
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static String routeName = 'Dashboard';
  static String routePath = '/dashboard';

  @override
  State<DashboardScreen> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardScreen> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseSyncService? _firebaseSyncService;
  final BleScannerService _bleScannerService = BleScannerService.instance;
  bool _syncing = false;
  bool _probeTriggering = false;

  @override
  void initState() {
    super.initState();
    // Web/Chrome: BLE + Firebase are not set up for runtime here, so keep the UI runnable.
    if (!kIsWeb) {
      _firebaseSyncService = FirebaseSyncService();
      _bleScannerService.start();
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _bleScannerService.stop();
    }
    super.dispose();
  }

  Future<void> _syncNow() async {
    if (_syncing) return;
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sync is disabled on Chrome/Web. Use the Android device instead.'),
        ),
      );
      return;
    }
    if (_firebaseSyncService == null) return;
    setState(() => _syncing = true);
    final result = await _firebaseSyncService!.syncOfflineRecords();
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F9FA),
          automaticallyImplyLeading: true,
          title: Text(
            'Dashboard',
            style: FlutterFlowTheme.of(context).titleLarge.override(
                  font: GoogleFonts.interTight(
                    fontWeight: FontWeight.bold,
                    fontStyle:
                        FlutterFlowTheme.of(context).titleLarge.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).primaryText,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.bold,
                  fontStyle: FlutterFlowTheme.of(context).titleLarge.fontStyle,
                ),
          ),
          actions: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
              child: FlutterFlowIconButton(
                borderColor: Colors.transparent,
                borderRadius: 22,
                buttonSize: 44,
                icon: Icon(
                  Icons.notifications_none,
                  color: FlutterFlowTheme.of(context).primaryText,
                  size: 24,
                ),
                onPressed: () {
                  print('IconButton pressed ...');
                },
              ),
            ),
          ],
          centerTitle: false,
          elevation: 0,
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF2E7D32)),
                child: Text(
                  'AgroInsight',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.grid_view_rounded),
                title: const Text('Farm Heatmap'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FarmHeatmapScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('Recent Scans'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecentScansScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_location_alt_rounded),
                title: const Text('Register Farm'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FarmRegistrationScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        body: SafeArea(
          top: true,
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0, 8, 0, 16),
                  child: Text(
                    'Welcome, Lead Farmer 👋',
                    style: FlutterFlowTheme.of(context).headlineSmall.override(
                          font: GoogleFonts.interTight(
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .headlineSmall
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).primaryText,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                          fontStyle: FlutterFlowTheme.of(context)
                              .headlineSmall
                              .fontStyle,
                        ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: kIsWeb ? null : _bleScannerService.manualRescan,
                    child: AnimatedBuilder(
                      animation: _bleScannerService,
                      builder: (context, _) => Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 12,
                          color: Color(0x2243A047),
                          offset: Offset(
                            0,
                            4,
                          ),
                        )
                      ],
                      gradient: LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF2E7D32)],
                        stops: [0, 1],
                        begin: AlignmentDirectional(1, 1),
                        end: AlignmentDirectional(-1, -1),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Color(0x33FFFFFF),
                              shape: BoxShape.circle,
                            ),
                            child: Align(
                              alignment: AlignmentDirectional(0, 0),
                              child: Icon(
                                Icons.memory_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SYSTEM STATUS',
                                  style: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .override(
                                        font: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                        ),
                                        color: Color(0xCCFFFFFF),
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                ),
                                Text(
                                  _bleScannerService.statusText,
                                  style: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .override(
                                        font: GoogleFonts.interTight(
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleMedium
                                                  .fontStyle,
                                        ),
                                        color: Colors.white,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .fontStyle,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _bleScannerService.statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ].divide(SizedBox(width: 12)),
                      ),
                    ),
                  )),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Align(
                        alignment: AlignmentDirectional(0, 0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(120),
                          onTap: kIsWeb
                              ? null
                              : (_probeTriggering ? null : () async {
                                  if (_probeTriggering) return;
                                  setState(() => _probeTriggering = true);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Triggering hardware probe...'),
                                    ),
                                  );

                                  try {
                                    final triggerResult = await _bleScannerService
                                        .triggerProbe(
                                      timeout: const Duration(seconds: 15),
                                    );
                                    if (!context.mounted) return;

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SectorOverviewScreen(
                                          sectorId: triggerResult.sectorId,
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Probe trigger failed: ${e.toString()}',
                                        ),
                                      ),
                                    );
                                  } finally {
                                    if (!mounted) return;
                                    setState(() => _probeTriggering = false);
                                  }
                                }),
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 40,
                                  color: Color(0x80F57C00),
                                  offset: Offset(
                                    0,
                                    8,
                                  ),
                                )
                              ],
                              gradient: LinearGradient(
                                colors: [Color(0xFFD84315), Color(0xFFD84315)],
                                stops: [0, 1],
                                begin: AlignmentDirectional(1, 1),
                                end: AlignmentDirectional(-1, -1),
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_probeTriggering)
                                  const Center(
                                    child: SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 4,
                                      ),
                                    ),
                                  )
                                else ...[
                                  Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 56,
                                  ),
                                  Text(
                                    'SCAN LEAF',
                                    style:
                                        FlutterFlowTheme.of(context).titleLarge.override(
                                              font: GoogleFonts.interTight(
                                                fontWeight: FontWeight.w800,
                                                fontStyle: FlutterFlowTheme.of(context)
                                                    .titleLarge.fontStyle,
                                              ),
                                              color: Colors.white,
                                              letterSpacing: 2,
                                              fontWeight: FontWeight.w800,
                                              fontStyle: FlutterFlowTheme.of(context)
                                                  .titleLarge.fontStyle,
                                            ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          FFButtonWidget(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const FarmHeatmapScreen(),
                                ),
                              );
                            },
                            text: 'VIEW FARM HEATMAP',
                            options: FFButtonOptions(
                              width: double.infinity,
                              height: 52,
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                              iconPadding:
                                  EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                              color: Colors.transparent,
                              textStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    font: GoogleFonts.interTight(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                    color: Color(0xFFD84315),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                              elevation: 0,
                              borderSide: BorderSide(
                                color: Color(0xFFD84315),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          FFButtonWidget(
                            onPressed: _syncing ? null : _syncNow,
                            icon: _syncing
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                    ),
                                  )
                                : null,
                            text: _syncing ? 'SYNCING...' : 'SYNC OFFLINE RECORDS',
                            options: FFButtonOptions(
                              width: double.infinity,
                              height: 48,
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                              iconPadding:
                                  EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
                              color: Colors.transparent,
                              iconColor: FlutterFlowTheme.of(context)
                                  .secondaryText,
                              textStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    font: GoogleFonts.interTight(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                              elevation: 0,
                              borderSide: BorderSide(
                                color: Colors.transparent,
                                width: 0,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ].divide(SizedBox(height: 12)),
                      ),
                    ].divide(SizedBox(height: 24)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
