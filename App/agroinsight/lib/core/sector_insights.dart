/// Sector-specific copy for the overview screen (offline SQLite–driven demos).
class SectorInsightLine {
  const SectorInsightLine({required this.title, required this.body});

  final String title;
  final String body;
}

enum SectorThreatTier { healthy, caution, critical }

SectorThreatTier classifySectorThreat(String diseaseName, double confidence) {
  final n = diseaseName.trim().toLowerCase();
  if (n == 'healthy') return SectorThreatTier.healthy;

  final highImpact = n == 'leaf rust' ||
      n == 'coffee berry borer' ||
      n == 'coffee leaf miner' ||
      n == 'leaf miner';
  if (highImpact && confidence >= 80.0) {
    return SectorThreatTier.critical;
  }
  return SectorThreatTier.caution;
}

List<SectorInsightLine> sectorActionableInsights({
  required String sectorId,
  required String diseaseName,
  required double confidence,
  required int scansLast24h,
}) {
  final tier = classifySectorThreat(diseaseName, confidence);
  final confLabel = confidence.round().toString();
  final scanNote =
      scansLast24h <= 1 ? 'Latest reading drives this view.' : '$scansLast24h scans in this sector (last 24h).';

  if (tier == SectorThreatTier.healthy) {
    return [
      SectorInsightLine(
        title: 'Maintain current practices',
        body:
            'Sector $sectorId looks healthy ($confLabel% confidence). Keep regular scouting to catch early stress.',
      ),
      SectorInsightLine(
        title: 'Watch neighbouring rows',
        body:
            'If rust or miner appears nearby, increase walk-through frequency along the border of $sectorId.',
      ),
      SectorInsightLine(
        title: 'Log soil & shade',
        body:
            'Note irrigation and canopy changes here — they often precede secondary pest pressure in coffee.',
      ),
    ];
  }

  final n = diseaseName.trim().toLowerCase();
  if (n.contains('rust')) {
    return [
      SectorInsightLine(
        title: 'Isolate sector $sectorId',
        body:
            'Limit equipment and foot traffic through $sectorId until treatment reduces spore load. $scanNote',
      ),
      SectorInsightLine(
        title: 'Targeted fungicide pass',
        body:
            'Plan an application suited to leaf rust; model confidence is $confLabel% — verify with extension guidance.',
      ),
      SectorInsightLine(
        title: 'Scout adjacent sectors',
        body:
            'Check A–D rows touching $sectorId within 48h; rust often spreads along wind and drainage lines.',
      ),
    ];
  }

  if (n.contains('miner')) {
    return [
      SectorInsightLine(
        title: 'Remove damaged foliage in $sectorId',
        body:
            'Strip miner-tracked leaves into a bag and leave the field to reduce larval carryover. $scanNote',
      ),
      SectorInsightLine(
        title: 'Biological / low-toxic options',
        body:
            'Discuss miner-specific controls with your agronomist; confidence is $confLabel% for this detection.',
      ),
      SectorInsightLine(
        title: 'Monitor flush after prune',
        body:
            'New soft growth attracts miners — schedule an extra visual pass 7–10 days after pruning near $sectorId.',
      ),
    ];
  }

  if (n.contains('borer')) {
    return [
      SectorInsightLine(
        title: 'Strip-pick ripe cherry in $sectorId',
        body:
            'Berry borer pressure rises with overripe fruit; prioritize harvest hygiene here. $scanNote',
      ),
      SectorInsightLine(
        title: 'Trap & bio-control check',
        body:
            'Confirm trap density and beneficial releases with your cooperative technical team.',
      ),
      SectorInsightLine(
        title: 'Flag trees for follow-up',
        body:
            'Mark worst trees in $sectorId for removal or heavy pruning if damage exceeds threshold.',
      ),
    ];
  }

  return [
    SectorInsightLine(
      title: 'Re-scan sector $sectorId',
      body:
          'Latest model read: ${diseaseName.trim()} at $confLabel% confidence. $scanNote',
    ),
    SectorInsightLine(
      title: 'Cross-check visually',
      body:
          'Confirm symptoms on-site before treatment; AI assists but does not replace field diagnosis.',
    ),
    SectorInsightLine(
      title: 'Update cooperative log',
      body:
            'Record actions taken in $sectorId so heatmap and sync reflect your response for the team.',
    ),
  ];
}
