import 'package:test/test.dart';

import 'package:selectable_entities/bloc/selectable_entities_bloc.dart';

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
  group("SelectableEntitiesBloc", () {
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

    test("excludeSelectedEntitiesFromAllEntities", () async {
      final bloc = SelectableEntitiesBloc<Tag>(
        allEntities: tags,
        selectedEntities: [tags[1]],
      );

      final entities = await bloc.excludeSelectedEntitiesFromAllEntities(
        allEntities: tags,
        selectedEntities: [tags[1]],
      );

      expect(entities.length, equals(1));
      expect(entities.first, equals(tags[0]));
    });

    test("CheckSelectedEntities", () async {
      final bloc = SelectableEntitiesBloc<Tag>(
        allEntities: tags,
        selectedEntities: [tags[1]],
      );

      final event = CheckSelectedEntities<Tag>();
      bloc.eventController.add(event);

      await for (final state in bloc.stateStream) {
        if (state is SelectedEntitiesChanged<Tag>) {
          expect(state.entities, equals([tags[1]]));
          break;
        }
      }
    });

    test("ExcludeSelectedEntitiesFromAllEntities", () async {
      final bloc = SelectableEntitiesBloc<Tag>(
        allEntities: tags,
        selectedEntities: [tags[1]],
      );

      final event = ExcludeSelectedEntitiesFromAllEntities<Tag>();
      bloc.eventController.add(event);

      await for (final state in bloc.stateStream) {
        if (state is EntitiesChanged<Tag>) {
          expect(state.entities, equals([tags[0]]));
          break;
        }
      }
    });

    test("EntitySelected", () async {
      final bloc = SelectableEntitiesBloc<Tag>(
        allEntities: tags,
        selectedEntities: [tags[1]],
      );

      final event = EntitySelected<Tag>(entity: tags[0]);
      bloc.eventController.add(event);

      await for (final state in bloc.stateStream) {
        if (state is EntitySelect<Tag>) {
          expect(state.entity, equals(tags[0]));
          continue;
        }

        if (state is SelectedEntitiesChanged<Tag>) {
          expect(state.entities.length, equals(2));
          expect(state.entities.first, equals(tags[1]));
          expect(state.entities.last, equals(tags[0]));
          continue;
        }

        if (state is EntitiesChanged<Tag>) {
          expect(state.entities, isEmpty);
          break;
        }
      }
    });

    test("EntityDeselected", () async {
      final bloc = SelectableEntitiesBloc<Tag>(
        allEntities: tags,
        selectedEntities: [tags[1]],
      );

      final event = EntityDeselected<Tag>(entity: tags[1]);
      bloc.eventController.add(event);

      await for (final state in bloc.stateStream) {
        if (state is EntityDeselect<Tag>) {
          expect(state.entity, equals(tags[1]));
          continue;
        }

        if (state is SelectedEntitiesChanged<Tag>) {
          expect(state.entities, isEmpty);
          continue;
        }

        if (state is EntitiesChanged<Tag>) {
          expect(state.entities.length, equals(2));
          expect(state.entities.first, equals(tags[0]));
          expect(state.entities.last, equals(tags[1]));
          break;
        }
      }
    });

    test("EntitiesFilterChanged", () async {
      final bloc = SelectableEntitiesBloc<Tag>(
        allEntities: tags,
        selectedEntities: [tags[1]],
        onFilterChange: (parameters, tag) {
          if (parameters == null) return false;

          return parameters.name.isEmpty
              ? true
              : tag.name.toLowerCase().contains(parameters.name.toLowerCase());
        },
      );

      final filterParameters = EntitiesFilterParameters(name: "first");
      final event = EntitiesFilterChanged<Tag>(
        entitiesFilterParameters: filterParameters,
      );

      bloc.eventController.add(event);

      await for (final state in bloc.stateStream) {
        if (state is EntitiesChanged<Tag>) {
          expect(state.entities.length, equals(1));
          expect(state.entities.first, equals(tags[0]));
          break;
        }
      }
    });

    test("EntitiesFilterChanged", () async {
      final bloc = SelectableEntitiesBloc<Tag>(
        allEntities: tags,
        selectedEntities: [tags[1]],
        onFilterChange: (parameters, tag) {
          if (parameters == null) return false;

          return parameters.name.isEmpty
              ? true
              : tag.name.toLowerCase().contains(parameters.name.toLowerCase());
        },
      );

      final filterParameters = EntitiesFilterParameters(name: "second");
      final event = EntitiesFilterChanged<Tag>(
        entitiesFilterParameters: filterParameters,
      );

      bloc.eventController.add(event);

      await for (final state in bloc.stateStream) {
        if (state is EntitiesChanged<Tag>) {
          expect(state.entities, isEmpty);
          break;
        }
      }
    });
  });
}
