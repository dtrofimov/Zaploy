# Zaploy

Zaploy is an experimental project to develop wrapper libraries for Salesforce iOS SDK.

PseudoSmartStore library is finished, CoreDataSoup library is not finished (see Project Status section).

## Some Details about Salesforce iOS SDK

The regular usage of [Salesforce iOS SDK](https://github.com/forcedotcom/SalesforceMobileSDK-iOS) includes using **SmartStore** as a database and **MobileSync** (formerly SmartSync) as a synchronization system (a kind-of-smart wrapper around REST).

SmartStore consists of tables named **soups**, containing arbitrary JSON records. Within a soup, some fields may be **indexed** (not to confuse with regular database indices), so that they be used in queries written in **SmartSQL** language (a query language of SmartStore). There is no built-in API to access these records as Objective-C/Swift objects with type-safe fields, the fetched records are just instances of `NSDictionary` parsed from JSON directly. Under the hood, SmartStore uses SQLite database, storing JSON strings, plus additional columns for indexed fields (still duplicated in a JSON string), and converts SmartSQL to a regular SQL. As a result, SmartStore is slower and less convenient in comparison with CoreData or Realm.

MobileSync is a synchronization system, which uses SmartStore and SF REST API. It has some useful built-in features like automatic page handling for large requests, additive synchronization of newly updated records, cleaning ghosts (the records which are removed on the backend, or don't match the query anymore).

As a result, it would be great to use MobileSync for SF synchronization purposes, but to avoid using SmartStore in favor of CoreData or Realm.

## Statement of the Problem

Unfortunately, MobileSync is highly coupled with SmartStore, as it uses an instance of `SFSmartStore` directly. And there's no legal way to replace SmartStore with another database, or to override SmartStore functionality in a corresponding manner.

On the other hand, `SFSmartStore` operates in Objective-C runtime, so we can replace it with another object implementing the same methods. Some specific methods, used by MobileSync, should be implemented to call an external storage. Other methods should be routed to a regular SmartStore instance, with a regular method calling or with message forwarding.

The objective is to develop such proxy (`PseudoSmartStore`), providing a reusable public inverface, which allows attaching arbitrary external storages, implementing some specific protocol (`ExternalSoup`).

Another objective is to implement this protocol for popular database frameworks, and to provide all the neccessary utils to setup the mapping between plain JSON objects and the database objects. To begin with, `CoreDataSoup` is an implementation of `ExternalSoup` for a CoreData entity.

## Project Status

PseudoSmartStore is finished and tested with Salesforce iOS SDK 8.1.0. It's a separate build target of Zaploy project within its own folder, and can be easily integrated to a real-life project.

CoreDataSoup is mostly implemented, but still not finished, and not fully tested. It still lacks some important features (the most critical one is marking created / updated / deleted entries, which is neccessary in read-write projects). Currently I have no plans for finishing it.
