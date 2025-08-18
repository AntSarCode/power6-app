enum UserTier { free, plus, pro, elite }

UserTier normalizeTier(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'plus':
      return UserTier.plus;
    case 'pro':
      return UserTier.pro;
    case 'elite':
      return UserTier.elite;
    default:
      return UserTier.free;
  }
}

const _tierRank = {
  UserTier.free: 0,
  UserTier.plus: 1,
  UserTier.pro:  2,
  UserTier.elite:3,
};

bool hasAccess(UserTier requiredTier, String? userTierRaw) {
  final userTier = normalizeTier(userTierRaw);
  return _tierRank[userTier]! >= _tierRank[requiredTier]!;
}
