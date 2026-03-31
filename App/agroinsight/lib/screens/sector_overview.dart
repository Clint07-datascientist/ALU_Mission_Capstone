import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/database/database_helper.dart';
import '../core/geo/sector_math.dart';
import '../core/sector_insights.dart';

/// Sector overview driven by the latest SQLite scan for that grid cell.
class SectorOverviewScreen extends StatefulWidget {
  const SectorOverviewScreen({
    super.key,
    required this.sectorId,
    this.queryPairedDbSector = false,
  });

  /// Tile label (e.g. **B1** on the heatmap).
  final String sectorId;

  /// When `true` (heatmap taps), SQLite is read from [SectorGrid.pairedSectorId] so
  /// **B1** shows **B3**'s stored diagnosis, etc. Leave `false` for GPS/scan flows.
  final bool queryPairedDbSector;

  static String routeName = 'SectorOverview';
  static String routePath = '/sectorOverview';

  @override
  State<SectorOverviewScreen> createState() => _SectorOverviewWidgetState();
}

class _SectorOverviewWidgetState extends State<SectorOverviewScreen> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool _loading = true;
  Map<String, dynamic>? _latestRecord;
  int? _farmId;
  int _scansLast24h = 0;

  @override
  void initState() {
    super.initState();
    _loadSectorData();
  }

  Future<void> _loadSectorData() async {
    final farm = await DatabaseHelper.instance.getLatestFarm();
    if (!mounted) return;
    if (farm == null) {
      setState(() {
        _loading = false;
        _farmId = null;
        _latestRecord = null;
      });
      return;
    }
    final farmId = farm['id'] as int;
    final dbSectorId = widget.queryPairedDbSector
        ? SectorGrid.pairedSectorId(widget.sectorId)
        : widget.sectorId;
    final rec = await DatabaseHelper.instance.getLatestRecordForFarmSector(
      farmId: farmId,
      sectorId: dbSectorId,
    );
    final since = DateTime.now().subtract(const Duration(hours: 24));
    final count = await DatabaseHelper.instance.countRecordsForFarmSectorSince(
      farmId: farmId,
      sectorId: dbSectorId,
      since: since,
    );
    if (!mounted) return;
    setState(() {
      _farmId = farmId;
      _latestRecord = rec;
      _scansLast24h = count;
      _loading = false;
    });
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
          backgroundColor: Colors.white,
          automaticallyImplyLeading: true,
          title: Text(
            'Sector ${widget.sectorId} Overview',
            style: FlutterFlowTheme.of(context).titleMedium.override(
                  font: GoogleFonts.interTight(
                    fontWeight: FontWeight.w600,
                    fontStyle:
                        FlutterFlowTheme.of(context).titleMedium.fontStyle,
                  ),
                  color: const Color(0xFF212121),
                  fontSize: 17,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                  fontStyle:
                      FlutterFlowTheme.of(context).titleMedium.fontStyle,
                ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
              child: FlutterFlowIconButton(
                borderColor: Colors.transparent,
                borderRadius: 22,
                borderWidth: 0,
                buttonSize: 44,
                icon: const Icon(
                  Icons.share_outlined,
                  color: Color(0xFF212121),
                  size: 22,
                ),
                onPressed: () {},
              ),
            ),
          ],
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          top: true,
          child: _loading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: _sectorBody(context),
                  ),
                ),
        ),
      ),
    );
  }

  List<Widget> _sectorBody(BuildContext context) {
    if (_farmId == null) {
      return [
        const SizedBox(height: 48),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Register your farm first, then open sectors from the heatmap.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF757575),
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ),
      ];
    }
    if (_latestRecord == null) {
      return [
        const SizedBox(height: 48),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'No scan data for Sector ${widget.sectorId} in the last day. '
            'Run a probe scan or open the dashboard in demo mode to seed the grid.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF757575),
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ),
      ];
    }

    final diseaseName =
        (_latestRecord!['disease_name'] as String?)?.trim() ?? 'Unknown';
    final confidence =
        ((_latestRecord!['confidence_score'] as num?) ?? 0).toDouble();
    final tier = classifySectorThreat(diseaseName, confidence);
    final insights = sectorActionableInsights(
      sectorId: widget.sectorId,
      diseaseName: diseaseName,
      confidence: confidence,
      scansLast24h: _scansLast24h,
    );

    return [
      _statusCard(context, diseaseName, confidence, tier),
      _insightsCard(context, insights),
    ]
        .divide(const SizedBox(height: 16))
        .addToStart(const SizedBox(height: 20))
        .addToEnd(const SizedBox(height: 28));
  }

  Widget _statusCard(
    BuildContext context,
    String diseaseName,
    double confidence,
    SectorThreatTier tier,
  ) {
    final borderColor = switch (tier) {
      SectorThreatTier.healthy => const Color(0xFF2E7D32),
      SectorThreatTier.caution => const Color(0xFFD84315),
      SectorThreatTier.critical => const Color(0xFFE53935),
    };
    final shadowTint = switch (tier) {
      SectorThreatTier.healthy => const Color(0x1A2E7D32),
      SectorThreatTier.caution => const Color(0x1AD84315),
      SectorThreatTier.critical => const Color(0x1AE53935),
    };
    final iconBg = switch (tier) {
      SectorThreatTier.healthy => const Color(0xFFE8F5E9),
      SectorThreatTier.caution => const Color(0xFFFFF3E0),
      SectorThreatTier.critical => const Color(0xFFFCE4EC),
    };
    final iconColor = switch (tier) {
      SectorThreatTier.healthy => const Color(0xFF2E7D32),
      SectorThreatTier.caution => const Color(0xFFE65100),
      SectorThreatTier.critical => const Color(0xFFE53935),
    };
    final titleColor = iconColor;
    final tag1 = switch (tier) {
      SectorThreatTier.healthy => ('STATUS', const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
      SectorThreatTier.caution => ('REVIEW', const Color(0xFFFFF3E0), const Color(0xFFE65100)),
      SectorThreatTier.critical => ('DISEASE', const Color(0xFFFCE4EC), const Color(0xFFE53935)),
    };
    final tag2 = switch (tier) {
      SectorThreatTier.healthy => ('HEALTHY', const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
      SectorThreatTier.caution => ('MODERATE', const Color(0xFFFFF3E0), const Color(0xFFE65100)),
      SectorThreatTier.critical => ('HIGH RISK', const Color(0xFFFFF3E0), const Color(0xFFE65100)),
    };
    final iconData = switch (tier) {
      SectorThreatTier.healthy => Icons.eco_outlined,
      SectorThreatTier.caution => Icons.warning_amber_rounded,
      SectorThreatTier.critical => Icons.coronavirus_outlined,
    };

    final confPct = confidence.clamp(0.0, 100.0);
    final confLabel = '${confPct.round()}%';
    final scanLine = _scansLast24h <= 1
        ? 'Latest scan in Sector ${widget.sectorId}.'
        : '$_scansLast24h scans in Sector ${widget.sectorId} (last 24h).';

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 18, 0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              color: shadowTint,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _pill(context, tag1.$1, tag1.$2, tag1.$3),
                  const SizedBox(width: 8),
                  _pill(context, tag2.$1, tag2.$2, tag2.$3),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: iconColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DETECTED CONDITION',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9E9E9E),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          diseaseName.toUpperCase(),
                          style: GoogleFonts.interTight(
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                            fontSize: 22,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          scanLine,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF424242),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Model confidence',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF616161),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    confLabel,
                    style: GoogleFonts.interTight(
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: confPct / 100.0,
                  minHeight: 10,
                  backgroundColor: iconBg,
                  valueColor: AlwaysStoppedAnimation<Color>(titleColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(
    BuildContext context,
    String text,
    Color bg,
    Color fg,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 5, 10, 5),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: fg,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _insightsCard(
    BuildContext context,
    List<SectorInsightLine> lines,
  ) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 18, 0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lightbulb_outlined,
                    color: Color(0xFFFF6D00),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Actionable insights',
                    style: GoogleFonts.interTight(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF212121),
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...List.generate(lines.length, (i) {
                final line = lines[i];
                return Padding(
                  padding: EdgeInsets.only(bottom: i == lines.length - 1 ? 0 : 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD84315),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.title,
                              style: GoogleFonts.interTight(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF212121),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              line.body,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF757575),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
