{-# LANGUAGE BangPatterns, FlexibleContexts, FlexibleInstances, MultiParamTypeClasses,
             ViewPatterns #-}
module HIP.Conversion (
  Convertible(..),
  toGray, toRGB, toHSI, toBinary,
  toGrayImage, toRGBImage, toHSIImage, toBinaryImage,
  rgbToGrays, hsiToGrays, graysToRGB, graysToHSI,
  toAlphaImage, fromAlphaImage,
  toComplexImage, fromComplexImage,
  toList
  ) where

import Prelude hiding (map)
import Data.Int
import Data.Word
import HIP.Interface (AImage(..), Convertible(..))
import HIP.Pixel

  
toGrayImage :: (Convertible px Gray, AImage img px, AImage img Gray) => img px -> img Gray
toGrayImage = map convert
{-# INLINE toGrayImage #-}


toRGBImage :: (Convertible px RGB, AImage img px, AImage img RGB) => img px -> img RGB
toRGBImage = map convert
{-# INLINE toRGBImage #-}


toHSIImage :: (Convertible px HSI, AImage img px, AImage img HSI) => img px -> img HSI
toHSIImage = map convert
{-# INLINE toHSIImage #-}


toBinaryImage :: (Convertible px Binary, AImage img px, AImage img Binary) =>
                 img px -> img Binary
toBinaryImage = map convert
{-# INLINE toBinaryImage #-}


toAlphaImage :: (AImage img px, AImage img (Alpha px), AlphaPixel px) =>
                img px -> img (Alpha px)
toAlphaImage = map addAlpha
{-# INLINE toAlphaImage #-}


fromAlphaImage :: (AImage img px, AImage img (Alpha px), AlphaPixel px) =>
                  img (Alpha px) -> img px
fromAlphaImage = map dropAlpha
{-# INLINE fromAlphaImage #-}



toComplexImage :: (AImage img px, AImage img (Complex px), ComplexPixel px) =>
                img px -> img (Complex px)
toComplexImage = map (:+: fromDouble 0)
{-# INLINE toComplexImage #-}


fromComplexImage :: (AImage img px, AImage img (Complex px), ComplexPixel px) =>
                  img (Complex px) -> img px
fromComplexImage = map real
{-# INLINE fromComplexImage #-}


rgbToGrays :: (AImage img RGB, AImage img Gray) => img RGB -> (img Gray, img Gray, img Gray)
rgbToGrays !img = (map (\(RGB r _ _) -> Gray r) img,
                   map (\(RGB _ g _) -> Gray g) img,
                   map (\(RGB _ _ b) -> Gray b) img)
{-# INLINE rgbToGrays #-}


hsiToGrays :: (AImage img HSI, AImage img Gray) => img HSI -> (img Gray, img Gray, img Gray)
hsiToGrays !img = (map (\(HSI h _ _) -> Gray h) img,
                   map (\(HSI _ s _) -> Gray s) img,
                   map (\(HSI _ _ i) -> Gray i) img)
{-# INLINE hsiToGrays #-}


fromGrays :: (AImage img Gray, AImage img px) =>
             (Double -> Double -> Double -> px) 
          -> (img Gray, img Gray, img Gray)
          -> img px
fromGrays !f !(img1@(dims -> (m1, n1)), img2@(dims -> (m2, n2)), img3@(dims -> (m3, n3)))
  | m1 == m2 && m2 == m3 && n1 == n2 && n2 == n3 =
    let newDims _ _ _ _ _ _ = (m1, n1)
        {-# INLINE newDims #-}
        getValue (Gray v) = v
        {-# INLINE getValue #-}
        newPx !getPx1 !getPx2 !getPx3 !i !j =
          f (getValue $ getPx1 i j) (getValue $ getPx2 i j) (getValue $ getPx3 i j)
        {-# INLINE newPx #-}
          in traverse3 img1 img2 img3 newDims newPx
  | otherwise = error ("Received images with inconsistent dimensions: "
                       ++ show img1 ++ ", " ++ show img2 ++ ", " ++ show img3)


graysToHSI :: (AImage img HSI, AImage img Gray) => (img Gray, img Gray, img Gray) -> img HSI
graysToHSI = fromGrays HSI
{-# INLINE graysToHSI #-}


graysToRGB :: (AImage img RGB, AImage img Gray) => (img Gray, img Gray, img Gray) -> img RGB
graysToRGB = fromGrays RGB
{-# INLINE graysToRGB #-}


-- | Converts an image to a list of Images that contain an internal type.
toList :: (AImage img (Channel px), AImage img px) => img px -> [img (Channel px)]
toList !img = toList' 0 where
  !pxArity = arity $ index img 0 0
  toList' !n = if n < pxArity then map (`ref` n) img:toList' (n+1) else []
{-# INLINE toList #-}
