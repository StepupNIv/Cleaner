import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // Use test IDs during development; replace with real IDs for production
  static const String _bannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111'; // test
  static const String _interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712'; // test
  static const String _rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917'; // test

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _bannerLoaded = false;
  bool _interstitialLoaded = false;
  bool _rewardedLoaded = false;

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      _loadBanner();
      _loadInterstitial();
      _loadRewarded();
    } catch (e) {
      // Ads failure must never crash app
    }
  }

  // ── Banner ────────────────────────────────────────────────────────────────
  void _loadBanner() {
    try {
      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) => _bannerLoaded = true,
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            _bannerAd = null;
            _bannerLoaded = false;
          },
        ),
      )..load();
    } catch (_) {}
  }

  BannerAd? get bannerAd => _bannerLoaded ? _bannerAd : null;

  // ── Interstitial ──────────────────────────────────────────────────────────
  void _loadInterstitial() {
    try {
      InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _interstitialLoaded = true;
          },
          onAdFailedToLoad: (_) {
            _interstitialLoaded = false;
          },
        ),
      );
    } catch (_) {}
  }

  void showInterstitial({VoidCallback? onDismissed}) {
    try {
      if (!_interstitialLoaded || _interstitialAd == null) {
        onDismissed?.call();
        return;
      }
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialLoaded = false;
          _loadInterstitial();
          onDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, _) {
          ad.dispose();
          _interstitialLoaded = false;
          _loadInterstitial();
          onDismissed?.call();
        },
      );
      _interstitialAd!.show();
    } catch (_) {
      onDismissed?.call();
    }
  }

  // ── Rewarded ──────────────────────────────────────────────────────────────
  void _loadRewarded() {
    try {
      RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _rewardedLoaded = true;
          },
          onAdFailedToLoad: (_) {
            _rewardedLoaded = false;
          },
        ),
      );
    } catch (_) {}
  }

  void showRewarded({
    required void Function() onEarned,
    VoidCallback? onDismissed,
  }) {
    try {
      if (!_rewardedLoaded || _rewardedAd == null) {
        onEarned(); // grant reward anyway if ad unavailable
        return;
      }
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedLoaded = false;
          _loadRewarded();
          onDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, _) {
          ad.dispose();
          _rewardedLoaded = false;
          _loadRewarded();
          onEarned();
        },
      );
      _rewardedAd!.show(
        onUserEarnedReward: (_, __) => onEarned(),
      );
    } catch (_) {
      onEarned();
    }
  }

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
