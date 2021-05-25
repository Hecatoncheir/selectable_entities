import 'package:flutter/material.dart';

import 'bloc/selectable_entities_bloc.dart';
export 'bloc/selectable_entities_bloc.dart';

typedef EntitiesDecorator = Widget Function(BuildContext, Widget);

class SelectableEntities<T> extends StatefulWidget {
  final SelectableEntitiesBloc _bloc;

  final Widget Function(BuildContext, T) _entityBuilder;
  final Widget Function(BuildContext, T) _selectedEntityBuilder;

  final Function(T, List<T>)? _onEntitySelected;
  final Function(T, List<T>)? _onEntityDeselected;

  final bool _withFilter;

  final EntitiesDecorator? _entitiesDecorator;

  final String filterNameFieldText;

  const SelectableEntities({
    required SelectableEntitiesBloc bloc,
    required Widget Function(BuildContext, T) entityBuilder,
    required Widget Function(BuildContext, T) selectedEntityBuilder,
    Function(T, List<T>)? onEntitySelected,
    Function(T, List<T>)? onEntityDeselected,
    Key? key,
    bool? withFilter,
    EntitiesDecorator? entitiesDecorator,
    this.filterNameFieldText = "Поиск по названию",
  })  : _bloc = bloc,
        _entityBuilder = entityBuilder,
        _selectedEntityBuilder = selectedEntityBuilder,
        _onEntitySelected = onEntitySelected,
        _onEntityDeselected = onEntityDeselected,
        _withFilter = withFilter ?? false,
        _entitiesDecorator = entitiesDecorator,
        super(key: key);

  @override
  _SelectableEntitiesState<T> createState() => _SelectableEntitiesState<T>();
}

class _SelectableEntitiesState<T> extends State<SelectableEntities<T>> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkSelectedEntitiesEvent = CheckSelectedEntities<T>();
    widget._bloc.eventController.add(checkSelectedEntitiesEvent);

    if (widget._withFilter) {
      final entitiesFilterChangedEvent = EntitiesFilterChanged<T>(
        entitiesFilterParameters: EntitiesFilterParameters(name: ""),
      );

      widget._bloc.eventController.add(entitiesFilterChangedEvent);
    } else {
      final excludeSelectedEntitiesFromAllEntities =
          ExcludeSelectedEntitiesFromAllEntities<T>();
      widget._bloc.eventController.add(excludeSelectedEntitiesFromAllEntities);
    }

    widget._bloc.stateStream.listen((state) {
      if (state is EntitySelect<T>) {
        final selectedEntity = state.entity;
        final selectedEntities = state.selectedEntities;

        final callback = widget._onEntitySelected;
        if (callback != null) {
          callback(selectedEntity, selectedEntities);
        }
      }

      if (state is EntityDeselect<T>) {
        final deselectedEntity = state.entity;
        final selectedEntities = state.selectedEntities;

        final callback = widget._onEntityDeselected;
        if (callback != null) {
          callback(deselectedEntity, selectedEntities);
        }
      }
    });

    return buildLayout(context);
  }

  Widget buildLayout(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSelectableEntitiesLayout(context),
        Expanded(
          child: buildAllEntitiesLayout(context),
        ),
      ],
    );
  }

  Widget buildSelectableEntitiesLayout(BuildContext context) {
    return StreamBuilder<SelectableEntitiesState>(
        stream: widget._bloc.stateStream
            .where((state) => state is SelectedEntitiesChanged<T>),
        builder: (context, snapshot) {
          final state = snapshot.data;
          if (state is SelectedEntitiesChanged<T>) {
            final selectedEntities = state.entities;
            return buildSelectableEntities(context, selectedEntities);
          }

          return Container();
        });
  }

  Widget buildFilterLayout(
    BuildContext context,
    EntitiesFilterParameters parameters,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: buildFilter(context, parameters),
    );
  }

  Widget buildFilter(
    BuildContext context,
    EntitiesFilterParameters parameters,
  ) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(6),
                    ),
                    color: Colors.white,
                  ),
                  child: TextFormField(
                    key: const Key("FormField-Name"),
                    initialValue: parameters.name,
                    onChanged: (text) {
                      final filterParameters = parameters;
                      filterParameters.name = text;

                      final event = EntitiesFilterChanged<T>(
                        entitiesFilterParameters: filterParameters,
                      );

                      widget._bloc.eventController.add(event);
                    },
                    decoration: InputDecoration(
                      hintText: widget.filterNameFieldText,
                      isDense: true,
                      border: OutlineInputBorder(gapPadding: 0),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildAllEntitiesLayout(BuildContext context) {
    return StreamBuilder<SelectableEntitiesState>(
        stream: widget._bloc.stateStream
            .where((state) => state is EntitiesChanged<T>),
        builder: (context, snapshot) {
          final state = snapshot.data;

          if (state is EntitiesChanged<T>) {
            final entities = state.entities;

            final decorator = widget._entitiesDecorator;

            if (decorator == null) {
              return buildAllEntitiesWithFilter(
                context,
                state.filterParameters,
                entities,
              );
            } else {
              return decorator(
                context,
                buildAllEntitiesWithFilter(
                  context,
                  state.filterParameters,
                  entities,
                ),
              );
            }
          }

          return Container();
        });
  }

  Widget buildAllEntitiesWithFilter(
    BuildContext context,
    EntitiesFilterParameters? entitiesFilterParameters,
    List<T> entities,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget._withFilter)
          buildFilterLayout(
            context,
            entitiesFilterParameters!,
          ),
        Flexible(
          child: buildAllEntities(context, entities),
        ),
      ],
    );
  }

  Widget buildAllEntities(
    BuildContext context,
    List<T> entities,
  ) {
    return Scrollbar(
      isAlwaysShown: entities.length < 10 ? false : true,
      controller: _scrollController,
      interactive: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Wrap(
          spacing: 6,
          children: [
            for (final entity in entities) buildEntity(context, entity),
          ],
        ),
      ),
    );
  }

  Widget buildEntity(BuildContext context, T entity) {
    if (widget._onEntitySelected != null) {
      return GestureDetector(
        onTap: () {
          final event = EntitySelected(entity: entity);
          widget._bloc.eventController.add(event);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: widget._entityBuilder(context, entity),
            ),
          ],
        ),
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: widget._entityBuilder(context, entity),
          ),
        ],
      );
    }
  }

  Widget buildSelectableEntities(BuildContext context, List<T> entities) {
    return Wrap(
      spacing: 6,
      children: [
        for (final entity in entities) buildSelectedEntity(context, entity),
      ],
    );
  }

  Widget buildSelectedEntity(BuildContext context, T entity) {
    if (widget._onEntityDeselected != null) {
      return GestureDetector(
        onTap: () {
          final event = EntityDeselected(entity: entity);
          widget._bloc.eventController.add(event);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: widget._selectedEntityBuilder(context, entity),
            ),
          ],
        ),
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: widget._selectedEntityBuilder(context, entity),
          ),
        ],
      );
    }
  }
}
