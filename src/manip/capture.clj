(ns manip.capture
  (:require [vision.core :as cv]))

(defn webcam []
  (let [c (cv/capture-from-cam 0)]
    (while true
      (cv/view :object (cv/query-frame c)))))

