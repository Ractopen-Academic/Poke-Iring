import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokeiring/features/auth/domain/entities/auth_user.dart';
import 'package:pokeiring/features/dex/data/repositories/dex_repository_impl.dart';
import 'package:pokeiring/features/dex/domain/entities/feline_dex_species.dart';
import 'package:pokeiring/features/dex/domain/entities/iring_dex_entry.dart';
import 'package:pokeiring/features/dex/presentation/pages/iring_dex_page.dart';
import 'package:pokeiring/features/dex/presentation/widgets/cat_detail_sheet.dart';
import 'package:pokeiring/features/dex/presentation/widgets/dex_progress_header.dart';
import 'package:pokeiring/features/dex/presentation/widgets/dex_species_card.dart';
import 'package:pokeiring/features/scanner/data/datasources/firebase_sightings_datasource.dart';
import 'package:pokeiring/features/scanner/domain/entities/cat_sighting.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mockUser = AuthUser(
    id: 'test-dex-explorer',
    email: 'dex@pokeiring.test',
    displayName: 'DexMaster',
    photoUrl: '',
    emailVerified: true,
  );

  group('FelineDexSpecies & IringDexEntry Entity', () {
    test('canonical species catalog has 16 items with unique dex numbers', () {
      final species = FelineDexSpecies.canonicalSpecies;
      expect(species.length, equals(16));

      final numbers = species.map((s) => s.dexNumber).toSet();
      expect(numbers.length, equals(16));
      expect(species.first.formattedNumber, equals('#001'));
      expect(species.last.formattedNumber, equals('#016'));
    });

    test('IringDexEntry.fromSightings calculates stats correctly', () {
      final species = FelineDexSpecies.canonicalSpecies[1]; // Puspin Calico
      final now = DateTime.now();

      final sightings = [
        CatSighting(
          id: 'sighting-1',
          userId: 'test-user',
          authorName: 'Tester',
          photoUrl: 'https://example.com/cat1.jpg',
          stickerUrl: '',
          latitude: 10.314,
          longitude: 123.972,
          geohash: 'w721x',
          barangay: 'Bankal',
          city: 'Lapu-Lapu City',
          region: 'Central Visayas',
          country: 'Philippines',
          breed: 'Calico (Puspin)',
          coatPattern: 'Calico',
          dominantColor: 'Tricolor',
          rarityMultiplier: 1.4,
          pawPoints: 110,
          quirk: 'Sunbathing on a wooden bench.',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
        CatSighting(
          id: 'sighting-2',
          userId: 'test-user',
          authorName: 'Tester',
          photoUrl: 'https://example.com/cat2.jpg',
          stickerUrl: '',
          latitude: 10.315,
          longitude: 123.973,
          geohash: 'w721x',
          barangay: 'Bankal',
          city: 'Lapu-Lapu City',
          region: 'Central Visayas',
          country: 'Philippines',
          breed: 'Calico',
          coatPattern: 'Calico',
          dominantColor: 'Tricolor',
          rarityMultiplier: 1.4,
          pawPoints: 140,
          quirk: 'Perched on store awning.',
          createdAt: now,
        ),
      ];

      final entry = IringDexEntry.fromSightings(
        species: species,
        matchedSightings: sightings,
      );

      expect(entry.isDiscovered, isTrue);
      expect(entry.timesSighted, equals(2));
      expect(entry.bestPawPoints, equals(140));
      expect(entry.bestLocation, equals('Bankal, Lapu-Lapu City'));
      expect(entry.firstSightedAt, equals(sightings.first.createdAt));
      expect(entry.lastSightedAt, equals(sightings.last.createdAt));
    });

    test('IringDexEntry.undiscovered returns zero progress', () {
      final species = FelineDexSpecies.canonicalSpecies[7]; // Siamese
      final entry = IringDexEntry.undiscovered(species);

      expect(entry.isDiscovered, isFalse);
      expect(entry.timesSighted, equals(0));
      expect(entry.bestPawPoints, equals(0));
      expect(entry.firstSightedAt, isNull);
    });
  });

  group('DexRepositoryImpl', () {
    test('maps fallback seed sightings into dex entries', () async {
      final dataSource = FirebaseSightingsDataSource();
      final repository = DexRepositoryImpl(dataSource: dataSource);

      final entries = await repository.getDexEntries('test-explorer');
      expect(entries.length, equals(16));

      final discovered = entries.where((e) => e.isDiscovered).toList();
      expect(discovered, isNotEmpty);
      expect(
        discovered.any((e) => e.species.coatPattern.contains('Calico')),
        isTrue,
      );
    });
  });

  group('Dex Widgets', () {
    testWidgets(
      'DexProgressHeader displays progress percentage and rank badge',
      (tester) async {
        final entries = [
          IringDexEntry(
            species: FelineDexSpecies.canonicalSpecies[0],
            isDiscovered: true,
            timesSighted: 2,
            bestPawPoints: 85,
          ),
          IringDexEntry(
            species: FelineDexSpecies.canonicalSpecies[1],
            isDiscovered: true,
            timesSighted: 1,
            bestPawPoints: 120,
          ),
          IringDexEntry.undiscovered(FelineDexSpecies.canonicalSpecies[2]),
          IringDexEntry.undiscovered(FelineDexSpecies.canonicalSpecies[3]),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DexProgressHeader(entries: entries)),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Iring-Dex Progress'), findsOneWidget);
        expect(find.text('2 of 4 Species Cataloged (50%)'), findsOneWidget);
        expect(find.text('Discovered'), findsOneWidget);
        expect(find.text('Remaining'), findsOneWidget);
        expect(find.text('+205 pts'), findsOneWidget);
      },
    );

    testWidgets(
      'DexSpeciesCard renders discovered species vs undiscovered card',
      (tester) async {
        final discoveredEntry = IringDexEntry(
          species: FelineDexSpecies.canonicalSpecies[1], // Calico
          isDiscovered: true,
          timesSighted: 3,
          bestPawPoints: 120,
        );

        final undiscoveredEntry = IringDexEntry.undiscovered(
          FelineDexSpecies.canonicalSpecies[10],
        ); // Bengal

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  DexSpeciesCard(entry: discoveredEntry, onTap: () {}),
                  DexSpeciesCard(entry: undiscoveredEntry, onTap: () {}),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Puspin Calico'), findsOneWidget);
        expect(find.text('#002'), findsOneWidget);
        expect(find.text('Sighted 3x • +120 pts'), findsOneWidget);

        expect(find.text('#011'), findsOneWidget);
        expect(find.text('???'), findsOneWidget);
        expect(find.text('Undiscovered'), findsOneWidget);
      },
    );

    testWidgets('CatDetailSheet opens and displays species field notes', (
      tester,
    ) async {
      final entry = IringDexEntry(
        species: FelineDexSpecies.canonicalSpecies[1],
        isDiscovered: true,
        timesSighted: 2,
        bestPawPoints: 120,
        bestLocation: 'Bankal, Lapu-Lapu City',
        firstSightedAt: DateTime(2026, 10, 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => CatDetailSheet.show(context, entry),
                child: const Text('Open Detail'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Detail'));
      await tester.pumpAndSettle();

      expect(find.text('Puspin Calico'), findsOneWidget);
      expect(find.text('Tricolor Fortune Cat'), findsOneWidget);
      expect(find.text('Species Field Notes'), findsOneWidget);
      expect(find.text('Typical Habitat'), findsOneWidget);
      expect(find.text('Your Discovery Records'), findsOneWidget);
      expect(find.text('Close Record'), findsOneWidget);
    });

    testWidgets(
      'IringDexPage renders species catalog and switches to album view',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: IringDexPage(user: mockUser)),
        );

        await tester.pumpAndSettle();

        expect(find.text('Iring-Dex'), findsOneWidget);
        expect(find.text('Species Catalog'), findsOneWidget);
        expect(find.text('Sightings Album'), findsOneWidget);
        expect(find.text('All Species'), findsOneWidget);
        expect(find.text('Puspin Native'), findsOneWidget);

        // Switch to Sightings Album tab
        await tester.tap(find.text('Sightings Album'));
        await tester.pumpAndSettle();

        expect(find.byType(CustomScrollView), findsOneWidget);
      },
    );
  });
}
