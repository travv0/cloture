(defpackage :cloture.test
  (:use :cl :alexandria :serapeum :fiveam :cloture :named-readtables)
  (:import-from :fset :equal? :seq :convert)
  (:shadowing-import-from :fset :map :set))
(in-package :cloture.test)
(in-readtable clojure-shortcut)

(def-suite cloture)
(in-suite cloture)

(defun run-cloture-tests ()
  (run! 'cloture))

(test read-vector
  (is (equal? (seq 1 2 3 :x) #_'[1 2 3 :X])))

(test read-map
  (is (equal? (map (:x 1) (:y 2) (:z 3))
              #_{:X 1 :Y 2 :Z 3})))

(test read-meta
  (let ((sym '#_^:dynamic *bar*))
    (is (symbolp sym))
    (is-true (meta-ref sym :|dynamic|))))

(test let
  (is (= 3 #_(let [x 1 y 2] (+ x y)))))

(test commas
  (is (equal '(:x :y :z) '#_(:X, :Y, :Z))))

(test qq
  (is (equal '(:x) #_`(~:X))))

(test reader-conditional
  (is (null #_#?(:clj 1)))
  (is (eql 1 #_#?(:cl 1 :clj 2))))

(test destructure-simple
  (is (equal '(1 2 3) #_(let ([x y z] [1 2 3])
                          (list x y z))))

  (is (equal '(1 2 3) #_(let ([x y z] '(1 2 3))
                          (list x y z)))))

(test destructure-as
  (is (equal '(1 2 3)
             (convert 'list
                      #_(let ([_ _ _ :as all] [1 2 3])
                          all))))
  (is (equal '(1 2 3)
             (convert 'list
                      #_(let ([_ _ _ :as all] '(1 2 3))
                          all)))))

(test destructure-rest
  (is (equal '(2 3) #_(let ([_ & ys] [1 2 3])
                        ys)))
  (is (equal '(2 3) #_(let ([_ & ys] '(1 2 3))
                        ys))))

(test destructure-rest-and-as
  (is (equal '(1 2 3)
             (convert 'list
                      #_(let ([_ & _ :as all] [1 2 3])
                          all))))
  (is (equal '(1 2 3)
             (convert 'list
                      #_(let ([_ & _ :as all] '(1 2 3))
                          all)))))

(test destructure-nested
  (is (equal '(1 2 3 4 5 6)
             #_(let [[[a] [[b]] c [x y z]] [[1] [[2]] 3 [4 5 6]]]
                 (list a b c x y z)))))

(test destructure-short
  (let ((l1 #_(list nil))
        (l2 #_(let [[x] '()]
                (list x))))
    (is (equal l1 l2))))

(test destructure-lisp-vector
  (is (equalp #(1 2 3 4 5)
              #_(let [[_ _ _ _ _ :as all] (CL:VECTOR 1 2 3 4 5)]
                  all)))
  (is (equal '(1 2 3 4 5)
             #_(let [[a b c d e] (CL:VECTOR 1 2 3 4 5)]
                 (list a b c d e)))))

(test fn
  (let ((bar
          #_(fn bar
              ([a b]
               (bar a b 100))
              ([a b c]
               (* a b c)))))
    (is (= 3000 (funcall bar 5 6)))
    (is (= 60 (funcall bar 5 6 2)))))

(test ->
  (is (listp (#_-> '((1 2) (3 4)))))
  (is (= 2 (#_-> '((1 2) (3 4)) first second)))
  (is (= 3 (#_-> '((1 2) (3 4)) second first))))

(test ->>
  (= 3/4 (#_->> 5 (+ 3) (/ 2) (- 1))))

(test loop-recur
  (let ((fact
          #_(fn [n]
              (loop [cnt n
                         acc 1]
                    (if (zero? cnt)
                        acc
                        (recur (dec cnt) (* acc cnt)))))))
    (= (funcall fact 10)
       (factorial 10))))

;;; You need `private' to prevent package variance on SBCL.
#_(def ^{:dynamic true :private true} foo* 0)
#_(defn ^:private get-foo [] foo*)

(test binding
  (is (= 0 #_foo*))
  (is (= 1 #_(let [foo* 1] foo*)))
  (is (= 0 #_(let [foo* 1] foo* (get-foo))))
  (is (= 1 #_(binding [foo* 1] foo*)))
  (is (= 1 #_(binding [foo* 1] (get-foo)))))

(test var
  (is (eql* (macroexpand-1 '#_foo*)
            #_(var foo*)
            #_#'foo*)))

(test set
  (is (typep #_#{1 2 3} 'set)))

(test seq
  (is (eql #_nil #_(seq '())))
  (is (eql #_nil #_(seq {})))
  (is (eql #_nil #_(seq #{})))
  (is (eql #_nil #_(seq [])))
  (is (set-equal '(1 2 3) #_(seq #{1 2 3})))
  (is (equal? (list (seq :x 1)
                    (seq :y 2))
              #_(seq {:X 1 :Y 2}))))

(test letfn
  (is (= 1
         #_(letfn [(fst [xs] (CL:FIRST xs))]
             (fst '(1 2 3)))))
  (is (= 1
         (funcall
          #_(letfn [(fst [xs] (CL:FIRST xs))]
              fst)
          '(1 2 3)))))

(test read-nothing
  (is (equal '(1 2) '#_(1 2 #_3))))

#_(def ^:private hello (fn hello [] "hello"))
#_(def ^{:private true :dynamic true} *hello* (fn hello [] "hello"))

(test lisp-1
  (is (equal "hello" #_(hello)))
  (is (equal "goodbye" #_(let [hello (constantly "goodbye")]
                           (hello))))
  (is (equal "goodbye" #_(let [[hello] (list (constantly "goodbye"))]
                           (hello)))))

(test pop
  (is (equal? (seq 1 2) (#_pop (seq 1 2 3))))
  (is (equal? (seq 1) (#_pop (seq 1 2))))
  (is (equal? (seq) (#_pop (seq 1))))
  (signals error (#_pop (seq))))

(test re-find
  (is #_(nil? (re-find #"sss" "Loch Ness")))
  (is #_(= "ss" (re-find #"s+" "dress")))
  (is #_(= ["success" "ucces" "s"] (re-find #"s+(.*)(s+)" "success"))))

(test re-matches
  (is #_(nil? (re-matches #"abc" "zzzabcxxx")))
  (is #_(= "abc" (re-matches #"abc" "abc")))
  (is #_(= ["abcxyz" "xyz"] (re-matches #"abc(.*)" "abcxyz"))))

(test qq-seq-ok
  #_(let [body '(x)]
      (5AM:IS
       (= `(let [x 1]
             ~@body)
          '(let [x 1] x)))))

(test qq-seq-1
  (is #_(= '[:x 1] `[~:x 1])))

(test qq-seq-2
  #_(let [x :x]
      (5AM:IS
       (= [:x] `[~x]))))

(test qq-map
  #_(let [form :form]
      (5AM:IS
       (= '{:expected :form}
          `{:expected ~form}))))

(test qq-set
  #_(let [x :x]
      (5AM:IS
       (= '#{:x} `#{~x}))))

(test eval-vector
  (is #_(= [(+ 1 1)] [2])))

(test no-nest-anons
  (signals error
    (read-clojure-from-string "#(#())")))

(test autogensym
  (destructuring-bind (sym val)
      #_(eval `(let [x# 1] (list 'x# x#)))
    (is (null (symbol-package sym)))
    (is (eql val 1))))

(test function-literal
  (is (= 1 (funcall #_#(do %) 1)))
  (is (= 1 #_(#(do %) 1)))
  (is (equal '(1) #_(#(list %) 1)))
  (is (equal '((1 2 3)) #_(#(list %&) 1 2 3)))
  (is (equal '(1 (2 3)) #_(#(list % %&) 1 2 3))))

(test deref-syntax
  (is (equal '(|clojure.core|:|deref| :|x|)
             #_'@:x)))

(test fn-destructure
  (is (equal '(1 2 3)
             (funcall #_(fn [[x y z]] (list x y z))
                      '(1 2 3)))))

(test fn-lisp-1
  (is (eql -1
           (funcall #_(fn [x y] (x y))
                    #'- 1))))

(test equality
  (is #_(= 0 0))
  (is (= (#_hash 0) (#_hash 0)))
  (is #_(not= 0 1))
  (is #_(not= (hash 0) (hash 1))))

#_(defmulti factorial identity)
#_(defmethod factorial 0 [_]  1)
#_(defmethod factorial :default [num]
    (* num (factorial (dec num))))

(test defmulti-identity
  (is (= 1 (#_factorial 0)))
  (is (= 1 (#_factorial 1)))
  (is (= 6 (#_factorial 3)))
  (is (= 5040 (#_factorial 7))))

#_(do
   (defmulti rand-str
       (fn [] (> (rand) 0.5)))

   (defmethod rand-str true
     [] "true")

    (defmethod rand-str false
      [] "false"))

(test defmulti-random
  (loop repeat 5 do
    (is (member (#_rand-str) '("false" "true") :test #'equal))))

(test quoted-literals
  (is (equal #_'(nil) #_(list nil)))
  (is (equal #_'(true) #_(list true)))
  (is (equal #_'(false) #_(list false))))

(test lazy-seq-equality
  (is #_(= (lazy-seq (cons 1 (lazy-seq '(2))))
           '(1 2)))
  (is (falsy? #_ (= (lazy-seq (cons 1 (lazy-seq '(2))))
                    '(1 3))))
  (is #_(= (lazy-seq (cons 1 (lazy-seq '(2))))
           (lazy-seq (cons 1 (lazy-seq '(2))))))
  (is #_(= (lazy-seq (cons 1 (lazy-seq '(2))))
           (lazy-seq (cons 1 (lazy-seq '(3))))))
  (is (truthy?
       #_(let [tail (lazy-seq (list 2 3))
               seq (lazy-seq (list 1 tail))]
           (= '(1) seq)
           (not (realized? tail))))))

#_(defn squares-odd [n]
    (cons (* n n) (lazy-seq (squares-odd (inc n)))))
#_(defn squares-even [n]
    (lazy-seq (cons (* n n) (squares-even (inc n)))))

(test lazy-seq
  (is #_(= (take 1 (squares-odd 1))
           (take 1 (squares-even 1)))))

(test cycle
  (is #_(= '(1 2 3 1 2 3 1 2 3 1)
           (doall 10 (cycle '(1 2 3))))))

(test concat
  (is #_(= '(1 2 3 4 5 6)
           (doall 10 (concat '(1 2 3) '(4 5 6))))))

(test take
  (is #_(= '(1 2 3 4 5 6)
           (doall (take 6 '(1 2 3 4 5 6))))))

(test repeat
  (is #_(= '(1 1 1 1 1)
           (doall 10 (repeat 5 1))))
  (is #_(= '(1 1 1)
           (doall 10 (repeat 3 1)))))

(test filter
  (is #_(= '(0 2 4 6 8)
           (doall (filter even? (range 10))))))

(test map
  ;; TODO cl-in-clojure reader macro, please!
  (is #_(= (CL:MAP 'CL:LIST (CL:FUNCTION CL:-) (SERAPEUM:RANGE 5))
           (doall (map - (range 5)))))
  (is #_(=
         (CL:MAP 'CL:LIST (CL:FUNCTION CL:-) (SERAPEUM:RANGE 5) (SERAPEUM:RANGE 5 10))
         (doall (map - (range 5) (range 5 10))))))

(test range
  (is #_(empty? (take 10 (range 0 0 0))))
  (is #_(= (CL:MAKE-LIST 5 :INITIAL-ELEMENT 0)
           (doall 5 (range 0 10 0))))
  (is #_(= (SERAPEUM:RANGE 10)
           (doall 10 (range)))))

(test drop-while
  (is #_(= '(2 4 6)
           (doall (drop-while odd? '(1 3 5 2 4 6))))))

(test interpose
  (is (truthy?
       #_(= '("one" "," "two" "," "three")
            (interpose "," '("one" "two" "three"))))))

(test group-by
  (let ((map #_(group-by count ["a" "as" "asd" "aa" "asdf" "qwer"])))
    (is (= (fset:size map) 4))))
