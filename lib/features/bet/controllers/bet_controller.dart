import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:centi_cresento/features/bet/repository/bet_repository.dart'; 
import '../../../models/bet_result.dart';

// Fournisseur pour le contrôleur BetController
final betControllerProvider = Provider((ref) {
  final betRepository = ref.watch(betRepositoryProvider);
  return BetController(
    betRepository: betRepository,
    ref: ref,
  );
});

// Classe BetController
class BetController {
  final BetRepository betRepository;
  final ProviderRef ref;

  BetController({
    required this.betRepository,
    required this.ref,
  });

  // Fournisseur pour récupérer les résultats des paris
  final betResultsProvider = StreamProvider<List<BetResultModel>>((ref) {
    final betRepository = ref.watch(betRepositoryProvider);
    return betRepository.getBetResults(); 
  });

  // Vous pouvez définir d'autres méthodes ou propriétés ici si nécessaire
}
