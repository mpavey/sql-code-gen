Imports System.Reflection
Imports System.Runtime.CompilerServices
Imports System.ComponentModel
Imports System.Text.RegularExpressions
Imports System.Collections.Concurrent

Public Module Extensions
    Private typeDictionary As New ConcurrentDictionary(Of Type, IList(Of PropertyInfo))()

    Public Function GetPropertiesForType(Of T)() As IList(Of PropertyInfo)
        'variables
        Dim type = GetType(T)

        'add to dictionary
        typeDictionary.TryAdd(type, type.GetProperties().ToList())

        'return
        Return typeDictionary(type)
    End Function

    <Extension()> _
    Public Function ToObject(Of T As New)(row As DataRow) As T
        'variables
        Dim properties As IList(Of PropertyInfo) = GetPropertiesForType(Of T)()

        'return
        Return row.CreateItemFromRow(Of T)(properties)
    End Function

    <Extension()> _
    Public Function ToList(Of T As New)(table As DataTable) As IList(Of T)
        'variables
        Dim result As IList(Of T) = New List(Of T)()

        'foreach
        For Each row As DataRow In table.Rows
            result.Add(row.ToObject(Of T)())
        Next

        'return
        Return result
    End Function

    <Extension()> _
    Private Function CreateItemFromRow(Of T As New)(row As DataRow, properties As IList(Of PropertyInfo)) As T
        'variables
        Dim item As New T()

        'foreach
        For Each p As PropertyInfo In properties
            'make sure a column exists in the table with this property name
            If row.Table.Columns.Contains(p.Name) Then
                'get the value from the current data row
                Dim value As Object = row(p.Name)

                'set property accordingly
                If value IsNot Nothing And value IsNot DBNull.Value Then
                    SetProperty(Of T)(item, p.Name, value)
                End If
            End If
        Next

        'return
        Return item
    End Function

    <Extension()> _
    Public Function GetProperty(Of T)(obj As T, propertyName As String) As String
        'reflection
        Dim propertyInfo As PropertyInfo = obj.GetType().GetProperty(propertyName, BindingFlags.Public Or BindingFlags.Instance Or BindingFlags.IgnoreCase)
        Dim propertyObj As Object = Nothing

        'make sure property is valid
        If propertyInfo IsNot Nothing Then
            propertyObj = propertyInfo.GetValue(obj, Nothing)
        End If

        'return value
        If propertyObj IsNot Nothing Then
            Return propertyObj.ToString()
        Else
            Return String.Empty
        End If
    End Function

    <Extension()> _
    Public Function SetProperty(Of T)(obj As T, propertyName As String, value As Object) As T
        'reflection
        Dim propertyInfo As PropertyInfo = obj.GetType().GetProperty(propertyName, BindingFlags.Public Or BindingFlags.Instance Or BindingFlags.IgnoreCase)

        'make sure property is valid
        If propertyInfo IsNot Nothing AndAlso propertyInfo.CanWrite Then
            propertyInfo.SetValue(obj, value, Nothing)
        End If

        'return
        Return obj
    End Function

    Public Function HasProperty(Of T As New)(propertyName) As Boolean
        'reflection
        Dim obj As T = New T()
        Dim propertyInfo As PropertyInfo = obj.GetType().GetProperty(propertyName, BindingFlags.Public Or BindingFlags.Instance Or BindingFlags.IgnoreCase)

        'see if property exists
        If propertyInfo IsNot Nothing Then
            Return True
        Else
            Return False
        End If
    End Function

    Private Function CreateDataTable(Of T)(Optional ByVal TableName As String = "") As DataTable
        'variables
        Dim Type As Type = GetType(T)
        Dim DT As New DataTable()
        Dim Properties As PropertyDescriptorCollection = TypeDescriptor.GetProperties(Type)

        'table name
        If TableName.HasValue Then
            DT.TableName = TableName
        Else
            DT.TableName = Type.Name
        End If

        'properties
        For Each p As PropertyDescriptor In Properties
            DT.Columns.Add(p.Name, If(Nullable.GetUnderlyingType(p.PropertyType), p.PropertyType))
        Next

        'return
        Return DT
    End Function

    <Extension()> _
    Public Function ToDataTable(Of T)(List As IList(Of T), Optional ByVal TableName As String = "") As DataTable
        'variables
        Dim DT As DataTable = CreateDataTable(Of T)(TableName)
        Dim Type As Type = GetType(T)
        Dim Properties As PropertyDescriptorCollection = TypeDescriptor.GetProperties(Type)

        'data
        For Each item As T In List
            'variables
            Dim row As DataRow = DT.NewRow()

            'property
            For Each p As PropertyDescriptor In Properties
                row(p.Name) = If(p.GetValue(item), DBNull.Value)
            Next

            'row
            DT.Rows.Add(row)
        Next

        'return
        Return DT
    End Function

    <Extension()> _
    Public Function HasValue(Value As String) As Boolean
        Return Not Value.IsBlank
    End Function

    <Extension()> _
    Public Function IsBlank(Value As String) As Boolean
        Dim ReturnValue As Boolean = True

        If Value IsNot Nothing Then
            ReturnValue = Value.Trim().Length = 0
        End If

        Return ReturnValue
    End Function

    <Extension()> _
    Public Function IsEqual(Value As String, CompareValue As String) As Boolean
        Dim ReturnValue As Boolean = False

        If Value IsNot Nothing AndAlso CompareValue IsNot Nothing Then
            ReturnValue = String.Compare(Value.Trim(), CompareValue.Trim(), StringComparison.OrdinalIgnoreCase) = 0
        End If

        Return ReturnValue
    End Function

    <Extension()> _
    Public Function IsEqual(ByVal Value As String, ByVal ParamArray CompareValues() As String) As Boolean
        If Value IsNot Nothing AndAlso CompareValues IsNot Nothing Then
            For Each CompareValue As String In CompareValues
                If Value.IsEqual(CompareValue) Then
                    Return True
                End If
            Next
        End If

        Return False
    End Function

    <Extension()> _
    Public Function ContainsValue(Value As String, CompareValue As String) As Boolean
        Dim ReturnValue As Boolean = False

        If Value IsNot Nothing AndAlso CompareValue IsNot Nothing Then
            ReturnValue = Value.Trim().IndexOf(CompareValue.Trim(), StringComparison.OrdinalIgnoreCase) >= 0
        End If

        Return ReturnValue
    End Function

    <Extension()> _
    Public Function StartsWithValue(Value As String, CompareValue As String) As Boolean
        Dim ReturnValue As Boolean = False

        If Value IsNot Nothing AndAlso CompareValue IsNot Nothing Then
            ReturnValue = Value.Trim().StartsWith(CompareValue.Trim(), StringComparison.OrdinalIgnoreCase)
        End If

        Return ReturnValue
    End Function

    <Extension()> _
    Public Function ReplaceValue(Value As String, Pattern As String, Replacement As String) As String
        Return Regex.Replace(Value, Regex.Escape(Pattern), Replacement, RegexOptions.IgnoreCase)
    End Function
End Module
