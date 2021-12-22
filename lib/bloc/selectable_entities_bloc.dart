import 'dart:async';
import 'package:pedantic/pedantic.dart';

import 'package:flutter/material.dart';

part 'exception_no_on_filter_change_callback_found.dart';
part 'entities_filter_parameters.dart';
part 'selectable_entities_event.dart';
part 'selectable_entities_state.dart';

class SelectableEntitiesBloc<T> {
  late final StreamController<SelectableEntitiesEvent> eventController;
  late final Stream<SelectableEntitiesEvent> eventStream;

  late final StreamController<SelectableEntitiesState> stateController;
  late final Stream<SelectableEntitiesState> stateStream;

  late final StreamSubscription eventSubscription;

  final List<T> allEntities;
  final List<T> selectedEntities;

  final bool Function(EntitiesFilterParameters?, T)? _onFilterChanged;
  EntitiesFilterParameters? _entitiesFilterParameters;

  List<T> _excludedSelectedEntitiesFromAllEntities;

  SelectableEntitiesBloc({
    required this.allEntities,
    required this.selectedEntities,
    bool Function(EntitiesFilterParameters?, T)? onFilterChange,
  })  : _excludedSelectedEntitiesFromAllEntities = [],
        _onFilterChanged = onFilterChange {
    eventController = StreamController<SelectableEntitiesEvent<T>>();
    eventStream = eventController.stream;

    stateController = StreamController<SelectableEntitiesState<T>>();
    stateStream = stateController.stream.asBroadcastStream();

    eventSubscription = eventStream.listen((event) async {
      if (event is CheckSelectedEntities<T>) {
        unawaited(_checkSelectedEntitiesHandler(event));
      }

      if (event is ExcludeSelectedEntitiesFromAllEntities<T>) {
        unawaited(_excludeSelectedEntitiesFromAllEntitiesHandler(event));
      }

      if (event is EntitySelected<T>) {
        unawaited(_entitySelectHandler(event));
      }

      if (event is EntityDeselected<T>) {
        unawaited(_entityDeselectHandler(event));
      }

      if (event is EntitiesFilterChanged<T>) {
        unawaited(_entitiesFilterChangedHandler(event));
      }
    });
  }

  void dispose() {
    eventSubscription.cancel();

    stateController.close();
    eventController.close();
  }

  @visibleForTesting
  Future<List<T>> excludeSelectedEntitiesFromAllEntities({
    required List<T> allEntities,
    required List<T> selectedEntities,
  }) async {
    return allEntities
        .where((element) => !selectedEntities.contains(element))
        .toList();
  }

  Future<void> _checkSelectedEntitiesHandler(
    CheckSelectedEntities<T> _,
  ) async {
    final state = SelectedEntitiesChanged<T>(entities: selectedEntities);
    stateController.add(state);
  }

  Future<void> _excludeSelectedEntitiesFromAllEntitiesHandler(
    ExcludeSelectedEntitiesFromAllEntities<T> _,
  ) async {
    _excludedSelectedEntitiesFromAllEntities =
        await excludeSelectedEntitiesFromAllEntities(
      allEntities: allEntities,
      selectedEntities: selectedEntities,
    );

    final state = EntitiesChanged<T>(
      entities: _excludedSelectedEntitiesFromAllEntities,
      filterParameters: _entitiesFilterParameters,
    );

    stateController.add(state);
  }

  Future<void> _entitySelectHandler(
    EntitySelected<T> event,
  ) async {
    final selectedEntity = event.entity;
    if (!selectedEntities.contains(selectedEntity)) {
      selectedEntities.add(selectedEntity);
    }

    final entitySelectState = EntitySelect<T>(
      entity: selectedEntity,
      selectedEntities: selectedEntities,
    );

    stateController.add(entitySelectState);

    final selectedEntitiesCheckedState =
        SelectedEntitiesChanged<T>(entities: selectedEntities);
    stateController.add(selectedEntitiesCheckedState);

    _excludedSelectedEntitiesFromAllEntities =
        await excludeSelectedEntitiesFromAllEntities(
      allEntities: allEntities,
      selectedEntities: selectedEntities,
    );

    final _filterParameters = _entitiesFilterParameters;
    final _onFilterChangedCallback = _onFilterChanged;

    if (_filterParameters != null) {
      if (_onFilterChangedCallback == null) {
        throw ExceptionNoOnFilterChangeCallbackFound();
      }

      final filteredEntities = _excludedSelectedEntitiesFromAllEntities
          .where(
            (element) => _onFilterChangedCallback(
              _filterParameters,
              element,
            ),
          )
          .toList();

      final state = EntitiesChanged<T>(
        entities: filteredEntities,
        filterParameters: _entitiesFilterParameters,
      );

      stateController.add(state);
    } else {
      final excludeSelectedEntitiesFromAllEntitiesReadyState =
          EntitiesChanged<T>(
        entities: _excludedSelectedEntitiesFromAllEntities,
        filterParameters: _entitiesFilterParameters,
      );

      stateController.add(excludeSelectedEntitiesFromAllEntitiesReadyState);
    }
  }

  Future<void> _entityDeselectHandler(
    EntityDeselected<T> event,
  ) async {
    final deselectedEntity = event.entity;
    if (selectedEntities.contains(deselectedEntity)) {
      selectedEntities.remove(deselectedEntity);
    }

    final entityDeselectState = EntityDeselect<T>(
      entity: deselectedEntity,
      selectedEntities: selectedEntities,
    );

    stateController.add(entityDeselectState);

    final selectedEntitiesCheckedState =
        SelectedEntitiesChanged<T>(entities: selectedEntities);
    stateController.add(selectedEntitiesCheckedState);

    _excludedSelectedEntitiesFromAllEntities =
        await excludeSelectedEntitiesFromAllEntities(
      allEntities: allEntities,
      selectedEntities: selectedEntities,
    );

    final _filterParameters = _entitiesFilterParameters;
    final _onFilterChangedCallback = _onFilterChanged;

    if (_filterParameters != null) {
      if (_onFilterChangedCallback == null) {
        throw ExceptionNoOnFilterChangeCallbackFound();
      }

      final filteredEntities = _excludedSelectedEntitiesFromAllEntities
          .where(
            (element) => _onFilterChangedCallback(
              _filterParameters,
              element,
            ),
          )
          .toList();

      final state = EntitiesChanged<T>(
        entities: filteredEntities,
        filterParameters: _entitiesFilterParameters,
      );

      stateController.add(state);
    } else {
      final state = EntitiesChanged<T>(
        entities: _excludedSelectedEntitiesFromAllEntities,
        filterParameters: _entitiesFilterParameters,
      );

      stateController.add(state);
    }
  }

  Future<void> _entitiesFilterChangedHandler(
    EntitiesFilterChanged<T> event,
  ) async {
    _entitiesFilterParameters = event.entitiesFilterParameters;

    _excludedSelectedEntitiesFromAllEntities =
        await excludeSelectedEntitiesFromAllEntities(
      allEntities: allEntities,
      selectedEntities: selectedEntities,
    );

    final _onFilterChangedCallback = _onFilterChanged;
    if (_onFilterChangedCallback == null) {
      throw ExceptionNoOnFilterChangeCallbackFound();
    }

    final filteredEntities = _excludedSelectedEntitiesFromAllEntities
        .where(
          (element) => _onFilterChangedCallback(
            _entitiesFilterParameters,
            element,
          ),
        )
        .toList();

    final state = EntitiesChanged<T>(
      entities: filteredEntities,
      filterParameters: _entitiesFilterParameters,
    );

    stateController.add(state);
  }
}
