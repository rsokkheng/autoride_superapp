// Display-only short name for a place. The full address is still what's
// stored/sent to the backend — this is only for what's shown on screen.
String getDisplayLocation({required String name, required String address}) {
  // 1. Prefer a real place name.
  if (name.trim().isNotEmpty && !isPlusCode(name)) {
    return name.trim();
  }

  final parts = address
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (parts.isEmpty) return address.trim();

  // 2. Drop any leading Plus Code segment(s) — e.g. "HW8F+W98, No. 150 St.
  // 128, Ministry of Health, Phnom Penh" — a bare code isn't useful on its
  // own.
  var start = 0;
  while (start < parts.length && isPlusCode(parts[start])) {
    start++;
  }
  final remaining = parts.sublist(start);
  if (remaining.isEmpty) return address.trim();

  // 3. Combine the first two segments — e.g. street/number + a nearby
  // landmark name: "No. 150 St. 128" + "Ministry of Health"
  // → "No. 150 St. 128 Ministry of Health". A single remaining segment
  // (already a full name, e.g. "National Payment Certification Agency
  // (NPCA)") is returned as-is.
  return remaining.take(2).join(' ');
}

bool isPlusCode(String value) {
  final text = value.trim();
  // Examples: "GVRV+MGR", "HW8F+W98" — applied to an already-isolated
  // address segment, so this matches the whole segment, not just a prefix.
  return RegExp(r'^[23456789CFGHJMPQRVWX]{4,8}\+[23456789CFGHJMPQRVWX]{2,}$')
      .hasMatch(text);
}
