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
  UserTier.pro: 2,
  UserTier.elite: 3,
};

bool hasAccess(UserTier requiredTier, String? userTierRaw) {
  final userTier = normalizeTier(userTierRaw);
  return _tierRank[userTier]! >= _tierRank[requiredTier]!;
}

String tierLabel(UserTier tier) {
  switch (tier) {
    case UserTier.free:
      return 'Free';
    case UserTier.plus:
      return 'Plus';
    case UserTier.pro:
      return 'Pro';
    case UserTier.elite:
      return 'Elite';
  }
}

String tierHeadline(UserTier tier) {
  switch (tier) {
    case UserTier.free:
      return 'Daily six-task planning';
    case UserTier.plus:
      return 'Build consistency with streaks and badges';
    case UserTier.pro:
      return 'Turn completed tasks into useful insight';
    case UserTier.elite:
      return 'Prepare for team accountability tools';
  }
}

List<String> tierBenefits(UserTier tier) {
  switch (tier) {
    case UserTier.free:
      return const <String>[
        'Plan up to six focus tasks each day',
        'Complete and review daily progress',
      ];
    case UserTier.plus:
      return const <String>[
        'Daily streak tracker',
        'Badge progression and detail',
        'Motivation prompts after completion moments',
      ];
    case UserTier.pro:
      return const <String>[
        'Everything in Plus',
        'Task timeline and completion insights',
        'CSV export for deeper review',
      ];
    case UserTier.elite:
      return const <String>[
        'Everything in Pro',
        'Early access to team accountability features',
        'Future group workflows and priority support',
      ];
  }
}
