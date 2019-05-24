//
//  UITableView+Extensions.swift
//  DeepDiff
//
//  Created by Khoa Pham.
//  Copyright © 2018 Khoa Pham. All rights reserved.
//

import UIKit

public extension UITableView {
  
  /// Animate reload in a batch update
  ///
  /// - Parameters:
  ///   - changes: The changes from diff
  ///   - section: The section that all calculated IndexPath belong
  ///   - insertionAnimation: The animation for insert rows
  ///   - deletionAnimation: The animation for delete rows
  ///   - replacementAnimation: The animation for reload rows
  ///   - updateData: Update your data source model
  ///   - completion: Called when operation completes
  func reload<T: DiffAware>(
    changes: [Change<T>],
    section: Int = 0,
    insertionAnimation: UITableView.RowAnimation = .automatic,
    deletionAnimation: UITableView.RowAnimation = .automatic,
    replacementAnimation: UITableView.RowAnimation = .automatic,
    updateData: () -> Void,
    completion: ((Bool) -> Void)? = nil) {
    
    let changesWithIndexPath = IndexPathConverter().convert(changes: changes, section: section)

    unifiedPerformBatchUpdates({
      updateData()
      self.insideUpdate(
        changesWithIndexPath: changesWithIndexPath,
        insertionAnimation: insertionAnimation,
        deletionAnimation: deletionAnimation
      )
    }, completion: { finished in
        self.unifiedPerformBatchUpdates({
            self.outsideUpdate(
                changesWithIndexPath: changesWithIndexPath,
                replacementAnimation: replacementAnimation
            )
        }, animated: false, completion: { finished in
            completion?(finished)
        })
    })
  }
  
  // MARK: - Helper

  private func unifiedPerformBatchUpdates(
    _ updates: (() -> Void),
    animated: Bool = true,
    completion: (@escaping (Bool) -> Void)) {

    UIView.performWithoutAnimation {
        beginUpdates()
        updates()
        endUpdates()
    }
    completion(true)
  }
  
  private func insideUpdate(
    changesWithIndexPath: ChangeWithIndexPath,
    insertionAnimation: UITableView.RowAnimation,
    deletionAnimation: UITableView.RowAnimation) {

    changesWithIndexPath.deletes.executeIfPresent {
      deleteRows(at: $0, with: deletionAnimation)
    }
    
    changesWithIndexPath.inserts.executeIfPresent {
      insertRows(at: $0, with: insertionAnimation)
    }
    
    changesWithIndexPath.moves.executeIfPresent {
      $0.forEach { move in
        moveRow(at: move.from, to: move.to)
      }
    }
  }

  private func outsideUpdate(
    changesWithIndexPath: ChangeWithIndexPath,
    replacementAnimation: UITableView.RowAnimation) {

    changesWithIndexPath.replaces.executeIfPresent {
      reloadRows(at: $0, with: replacementAnimation)
    }
  }
}
