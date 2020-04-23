import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:json_store/json_store.dart';
import 'package:mobx/mobx.dart';
import 'package:optional/optional_internal.dart';
import 'package:tw_wallet_ui/models/identity.dart';
import 'package:tw_wallet_ui/models/tw_point.dart';

part 'identity_store.g.dart';

const IDENTITIES_STORAGE_NAME = 'identities';
const IDENTITIES_NAME_KEY = 'name';
const SELECTED_INDEX_KEY = 'selected_index';

enum AssetsType { point, token }

class IdentityStore = IdentityStoreBase with _$IdentityStore;

String _itemKey(String name) {
  return '$IDENTITIES_NAME_KEY: $name';
}

abstract class IdentityStoreBase with Store {
  static final _db = JsonStore(dbName: IDENTITIES_STORAGE_NAME);

  IdentityStoreBase(this.identities, int selectedIndex) {
    searchName = '';
    _streamController = StreamController();
    futureStream = ObservableStream(_streamController.stream);
    _identitiesSort();
    selectIdentity(index: selectedIndex);
  }

  static Future<IdentityStore> fromJsonStore() async {
    int selectedIndex = await _db.getItem(SELECTED_INDEX_KEY).then((savedItem) {
      return savedItem != null ? savedItem[SELECTED_INDEX_KEY] : 0;
    });

    List<Identity> identities =
        Optional.ofNullable(await _db.getListLike('$IDENTITIES_NAME_KEY: %'))
            .map((listItems) =>
                listItems.map((item) => Identity.fromJson(item)).toList())
            .orElse([]);

    return IdentityStore(identities, selectedIndex);
  }

  @observable
  int selectedIndex;

  @observable
  List<Identity> identities;

  @observable
  String searchName;

  StreamController<ObservableFuture<Optional<TwPoint>>> _streamController;

  ObservableStream<ObservableFuture<Optional<TwPoint>>> futureStream;

  @computed
  Optional<Identity> get selectedIdentity => identities.isEmpty
      ? Optional.empty()
      : Optional.of(identities[selectedIndex]);

  @computed
  String get myName =>
      selectedIdentity.map((identity) => identity.name).orElse('');

  @computed
  String get myAddress =>
      selectedIdentity.map((identity) => identity.address).orElse('');

  @computed
  String get myBalance =>
      selectedIdentity.map((identity) => identity.point).orElse('0');

  void _identitiesSort() {
    identities.sort(
        (identity1, identity2) => identity1.name.compareTo(identity2.name));
  }

  void dispose() async {
    await _streamController.close();
  }

  @action
  void updateSearchName(String name) {
    searchName = name;
  }

  @action
  Future<void> clear() async {
    await _db.clearDataBase();
  }

  @action
  Future<void> selectIdentity({@required int index}) async {
    if (index >= 0 && index < identities.length) {
      await _db
          .setItem(SELECTED_INDEX_KEY, {SELECTED_INDEX_KEY: index}).then((_) {
        selectedIndex = index;
        return fetchLatestPoint();
      });
    }
  }

  @action
  Future<void> addIdentity({@required Identity identity}) async {
    _db.setItem(_itemKey(identity.name), identity.toJson()).then((_) {
      identities.add(identity);
      _identitiesSort();
      if (identities.length == 1) {
        selectIdentity(index: 0);
      }
    });
  }

  @action
  void updateSelectedIdentity(Identity identity) {
    int index = identities.indexWhere((other) => other.name == identity.name);
    if (index >= 0) {
      identities[index] = identity;
    } else {
      throw Exception('Identity updated not exist.');
    }
  }

  @action
  Future<void> deleteIdentity({@required int index}) async {
    if (index != selectedIndex) {
      assert(index >= 0 && index < identities.length);
      await _db.deleteItem(_itemKey(identities[index].name));
    }
  }

  @action
  void fetchLatestPoint() {
    _streamController.add(ObservableFuture(
        Future.value(selectedIdentity).then((selectedIdentity) async {
      if (selectedIdentity.isPresent) {
        return await TwPoint.fetchPoint(address: selectedIdentity.value.address)
            .then((fetchRes) {
          fetchRes.ifPresent((twPoint) => updateSelectedIdentity(
              selectedIdentity.value.rebuild(
                  (identity) => identity..point = twPoint.value.toString())));
          return fetchRes;
        });
      }
      return Optional.empty();
    })));
  }
}
