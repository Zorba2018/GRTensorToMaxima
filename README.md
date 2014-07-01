GRTensorToMaxima
================

This perl script takes in a GRTensor metric file (*.mpl) and translates it to a file (*.mac) that can be read by Maxima's ctensor.

Usage
------

```
grTensorToMaxima.pl GRTensorFile.mpl MaximaMetricFile.mac
maxima
(%i1) read("MaximaMetricFile.mac");
```

You do not need to initialize ctensor when you read from the translated file.
You should, however, check the metric file (in particular, the depends lines) to make sure there were no translation errors.
