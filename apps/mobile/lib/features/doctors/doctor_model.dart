class Doctor {
  Doctor.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        fullName = j['fullName'],
        slug = j['slug'],
        bio = j['bio'],
        photoUrl = j['photoUrl'],
        videoUrl = j['videoUrl'],
        fee = j['consultationFee'],
        rating = (j['ratingAvg'] as num).toDouble(),
        ratingCount = j['ratingCount'],
        city = j['city']['name'],
        specialties = [for (final s in j['specialties']) Specialty.fromJson(s['specialty'])],
        slots = [for (final s in (j['slots'] ?? [])) DateTime.parse(s['startsAt']).toLocal()];

  final String id, fullName, slug, bio, city;
  final String? photoUrl, videoUrl;
  final int fee, ratingCount;
  final double rating;
  final List<Specialty> specialties;
  final List<DateTime> slots;
}

class Specialty {
  Specialty.fromJson(Map<String, dynamic> j)
      : name = j['name'],
        slug = j['slug'],
        icon = j['icon'];
  final String name, slug;
  final String? icon;
}

class Option {
  Option.fromJson(Map<String, dynamic> j) : name = j['name'], slug = j['slug'];
  final String name, slug;
}
