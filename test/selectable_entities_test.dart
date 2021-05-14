import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:selectable_entities/selectable_entities.dart';

class Tag {
  int tagId;

  String name;

  String color;

  Tag({
    required this.tagId,
    required this.name,
    required this.color,
  });
}

void main() {
  group("SelectableEntities", () {
    late List<Tag> tags;

    setUpAll(() {
      tags = [
        Tag(
          tagId: 1,
          name: 'Test first bpmn tag name',
          color: "#ffffff",
        ),
        Tag(
          tagId: 2,
          name: 'Test second bpmn tag name',
          color: "#ffffff",
        )
      ];
    });

    testWidgets("build", (tester) async {
      final bloc = SelectableEntitiesBloc<Tag>(
        allEntities: tags,
        selectedEntities: [tags[1]],
      );

      final testWidget = SelectableEntities<Tag>(
        bloc: bloc,
        entityBuilder: (context, entity) {
          return Text(
            entity.name,
            key: Key("entity-id-" + entity.tagId.toString()),
          );
        },
        selectedEntityBuilder: (context, entity) {
          return Text(
            entity.name,
            key: Key("entity-id-" + entity.tagId.toString() + "--selected"),
          );
        },
      );

      final widget = MaterialApp(
        home: Scaffold(
          body: testWidget,
        ),
      );

      await tester.pumpWidget(widget);

      await tester.pumpAndSettle();

      expect(find.byKey(const Key("entity-id-1")), findsOneWidget);
      expect(find.byKey(const Key("entity-id-2")), findsNothing);
      expect(find.byKey(const Key("entity-id-1--selected")), findsNothing);
      expect(find.byKey(const Key("entity-id-2--selected")), findsOneWidget);
    });

    testWidgets("onSelect", (tester) async {
      Tag? selectedTag;
      List<Tag>? selectedTags;

      final bloc = SelectableEntitiesBloc<Tag>(
        allEntities: tags,
        selectedEntities: [tags[1]],
      );

      final testWidget = SelectableEntities<Tag>(
        bloc: bloc,
        onEntitySelected: (_selectedTag, _selectedTags) {
          selectedTag = _selectedTag;
          selectedTags = _selectedTags;
        },
        entityBuilder: (context, entity) {
          return Text(
            entity.name,
            key: Key("entity-id-" + entity.tagId.toString()),
          );
        },
        selectedEntityBuilder: (context, entity) {
          return Text(
            entity.name,
            key: Key("entity-id-" + entity.tagId.toString() + "--selected"),
          );
        },
      );

      final widget = MaterialApp(
        home: Scaffold(
          body: testWidget,
        ),
      );

      await tester.pumpWidget(widget);

      await tester.pumpAndSettle();

      expect(find.byKey(const Key("entity-id-1")), findsOneWidget);
      expect(find.byKey(const Key("entity-id-2")), findsNothing);
      expect(find.byKey(const Key("entity-id-1--selected")), findsNothing);
      expect(find.byKey(const Key("entity-id-2--selected")), findsOneWidget);

      expect(selectedTag, isNull);
      expect(selectedTags, isNull);

      await tester.tap(find.byKey(const Key("entity-id-1")));
      await tester.pump();

      expect(find.byKey(const Key("entity-id-1")), findsNothing);
      expect(find.byKey(const Key("entity-id-2")), findsNothing);
      expect(find.byKey(const Key("entity-id-1--selected")), findsOneWidget);
      expect(find.byKey(const Key("entity-id-2--selected")), findsOneWidget);

      expect(selectedTag, equals(tags[0]));
      expect(selectedTags!.length, equals(2));
    });

    testWidgets("onDeselect", (tester) async {
      Tag? deselectedTag;
      List<Tag>? selectedTags;

      final bloc = SelectableEntitiesBloc<Tag>(
        allEntities: tags,
        selectedEntities: [tags[1]],
      );

      final testWidget = SelectableEntities<Tag>(
        bloc: bloc,
        onEntityDeselected: (_deselectedTag, _selectedTags) {
          deselectedTag = _deselectedTag;
          selectedTags = _selectedTags;
        },
        entityBuilder: (context, entity) {
          return Text(
            entity.name,
            key: Key("entity-id-" + entity.tagId.toString()),
          );
        },
        selectedEntityBuilder: (context, entity) {
          return Text(
            entity.name,
            key: Key("entity-id-" + entity.tagId.toString() + "--selected"),
          );
        },
      );

      final widget = MaterialApp(
        home: Scaffold(
          body: testWidget,
        ),
      );

      await tester.pumpWidget(widget);

      await tester.pumpAndSettle();

      expect(find.byKey(const Key("entity-id-1")), findsOneWidget);
      expect(find.byKey(const Key("entity-id-2")), findsNothing);
      expect(find.byKey(const Key("entity-id-1--selected")), findsNothing);
      expect(find.byKey(const Key("entity-id-2--selected")), findsOneWidget);

      expect(deselectedTag, isNull);
      expect(selectedTags, isNull);

      await tester.tap(find.byKey(const Key("entity-id-2--selected")));
      await tester.pump();

      expect(find.byKey(const Key("entity-id-1")), findsOneWidget);
      expect(find.byKey(const Key("entity-id-2")), findsOneWidget);
      expect(find.byKey(const Key("entity-id-1--selected")), findsNothing);
      expect(find.byKey(const Key("entity-id-2--selected")), findsNothing);

      expect(deselectedTag, equals(tags[1]));
      expect(selectedTags!.length, equals(0));
    });

    testWidgets("onFilterChange", (tester) async {
      final bloc = SelectableEntitiesBloc<Tag>(
        allEntities: tags,
        selectedEntities: [tags[1]],
        onFilterChange: (parameters, tag) => parameters.name.isEmpty
            ? true
            : tag.name.toLowerCase().contains(parameters.name.toLowerCase()),
      );

      final testWidget = SelectableEntities<Tag>(
        bloc: bloc,
        withFilter: true,
        entityBuilder: (context, entity) {
          return Text(
            entity.name,
            key: Key("entity-id-" + entity.tagId.toString()),
          );
        },
        selectedEntityBuilder: (context, entity) {
          return Text(
            entity.name,
            key: Key("entity-id-" + entity.tagId.toString() + "--selected"),
          );
        },
      );

      final widget = MaterialApp(
        home: Scaffold(
          body: testWidget,
        ),
      );

      await tester.pumpWidget(widget);

      await tester.pumpAndSettle();

      expect(find.byKey(const Key("entity-id-1")), findsOneWidget);
      expect(find.byKey(const Key("entity-id-2")), findsNothing);
      expect(find.byKey(const Key("entity-id-1--selected")), findsNothing);
      expect(find.byKey(const Key("entity-id-2--selected")), findsOneWidget);

      expect(find.byKey(const Key("FormField-Name")), findsOneWidget);

      await tester.enterText(find.byKey(const Key("FormField-Name")), "first");
      await tester.pump();

      expect(find.byKey(const Key("entity-id-1")), findsOneWidget);
      expect(find.byKey(const Key("entity-id-2")), findsNothing);
      expect(find.byKey(const Key("entity-id-1--selected")), findsNothing);
      expect(find.byKey(const Key("entity-id-2--selected")), findsOneWidget);

      await tester.enterText(find.byKey(const Key("FormField-Name")), "second");
      await tester.pump();

      expect(find.byKey(const Key("entity-id-1")), findsNothing);
      expect(find.byKey(const Key("entity-id-2")), findsNothing);
      expect(find.byKey(const Key("entity-id-1--selected")), findsNothing);
      expect(find.byKey(const Key("entity-id-2--selected")), findsOneWidget);
    });
  });
}
